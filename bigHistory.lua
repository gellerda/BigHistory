-- Ver. 1.0
-- НАСТРОЙКА:
-- 1. В таблице tVars задаем пороговые значения thrV для каждого инструмента. Суммарные объемы выше этих порогов мы будем мониторить.
-- 2. Из этой же таблицы можно убрать ненужные или добавить нужные инструменты.
-- 3. Для настройки окошек можно в функции InitQTable() выставить ширину W, высоту H, местоположение VR_X.
-- 4. Нужно исправить, если нужно, пути для звуковых файлов во всех функциях с названиями Say... Сейчас звуковые файлы должны лежать в папке: "C:\\k\\sounds\\my\\"
-- 5. Поправить путь к файлу с дополнительными функциями "c:\lua\system.lua" если нужно. См. чуть ниже строку dofile("c:\\lua\\system.lua")




-- МОЯ НОТАЦИЯ:
-- 1. имена массивов/таблиц начинаются с префикса "t".
-- 2. Имена функций начинаются с большой буквы. Имена переменных - с маленькой. Имена констант содержат только заглавные буквы.

-- ВНИМАНИЕ СПРАВКА!!! При использовании функций для работы с собственными таблицами нумерация столбцов и колонок считается с единицы!

dofile("c:\\lua\\system.lua"); -- Разные универсальные функции не имеющие отношения к Квику.
dofile("c:\\lua\\stdquik.lua"); -- Разные универсальные функции не имеющие отношения к Квику.
dofile("c:\\lua\\stdorders.lua"); -- Разные универсальные функции не имеющие отношения к Квику.
dofile("c:\\lua\\my_math.lua"); -- 
dofile("c:\\lua\\BigHistory\\bigHistory_GUI.lua"); -- 
dofile("c:\\lua\\BigHistory\\bigHistory_say.lua"); -- 
--========================================================================================
is_run=true;
isDaySessionFinished=false;
lastTVS_i = 1; --getNumberOf("all_trades");

CURRENT_RATE = 12; -- Текущая ставка рефинансирования в процентах.

-- status строки в таблице квика можем иметь значения:
L_BROKEN=0; -- Уровень был пробит.
L_ACTIVE=1; -- Уровень не был пройден, устоял.

N_DAYS_FOR_THR = 1;
N_MAX_V_FOR_THR = 10;

-- tVars - таблица с различными переменными по каждому инструменту. Ключом таблицы служит sec_code(string). Каждый элемент таблицы - таблица:
-- thrV - порог объема, после которого эта информация выводится на экран.
-- lastP_B и lastP_S, last_oper, last_t_mcs  - по ТВС: последние цены сделок Buy и Sell, oper, t_mcs:
-- seria_sumMktV - суммарный объем в последней серии сделок (один ордер - серия последовательных сделок).
-- seria_sumBigLimV - суммарный объем встречных БОЛЬШИХ лимиток в последней серии.
-- seria_lastLevSumV - суммарный объем по последней цене. Считается только в рамках данной серии сделок!
-- seria_maxLevSumV, seria_maxLevP - максимальный суммарный объем по одной цене за эту серию сделок. И, собственно, эта цена.
-- seria_p0, seria_p1 - цены первой и последней сделок в последней серии. 
-- seria_t - время последней серии. 
-- auto_B/S - флаг включена ли функция авто-покупки/продажи по появлению гигантского лота.
-- DAYS_TO_MAT_DATE - число дней до погашения фьючерса.
-- lot_size - количество лотов спота во фьючерсе.
-- GO - гарантийное обеспечение фьюча.
tVars={ SBER = {class_code="TQBR", thrVInP=0.997, thrV=30000, fut_sec_code="SRZ5", chart_lbl="SBER",  fut_chart_lbl="SRU5", my_size=4},
		GAZP = {class_code="TQBR", thrVInP=0.997, thrV=6000, fut_sec_code="GZZ5", chart_lbl="GAZP",  fut_chart_lbl="GZU5",  my_size=3}, 
		LKOH = {class_code="TQBR", thrVInP=0.997, thrV=3000, fut_sec_code="LKZ5", chart_lbl="LKOH",  fut_chart_lbl="LKU5",  my_size=1},
		VTBR = {class_code="TQBR", thrVInP=0.993, thrV=7000, fut_sec_code="VBZ5", chart_lbl="VTBR",  fut_chart_lbl="VBU5",  my_size=4},
		USD000UTSTOM = {class_code="CETS", thrVInP=0.998, thrV=10000, fut_sec_code="SiZ5", chart_lbl="USD000UTSTOM",  fut_chart_lbl="SiU5",  my_size=1}}
		
-- Текущие активные лимитные уровни - цены, по которым прошел объем, но лимитник так и не пробили. 
-- После пробития лимитного уровня, удаляем данную запись из массива.
-- tActive_X[sec_code][p] содержит цену, до которой дошли не пробив данного уровня. 
-- !!! Внимание! Цены tActLev_B - это лимитники на покупку, tActLev_S - на продажу. 
tActLev_B={};
tActLev_S={};

-- tStakan - двумерная таблица с информацией о ценах и объемах, прошедших по данным ценам.
-- Ключом таблицы служит sec_code(string) и цена(number). Каждый элемент таблицы - таблица:
-- {maxQ_Ofr, maxQ_Bid, sumV_B, sumV_S, sumBigV_B, sumBigV_S, Q_Bid, Q_Ofr, t_B, t_S, isHugeBid, isHugeOfr} : 
-- sumV_B - суммарные объем сделок BUY, с момента последнего прошития этого уровня СОПРОТИВЛЕНИЯ. maxQ_Ofr - максимальный объем офера за это время.
-- sumV_S - суммарные объем сделок SELL, с момента последнего прошития этого уровня ПОДДЕРЖКИ. maxQ_Bid - максимальный объем бида за это время.
-- sumBigV_x - то же, что sumV_x, но учитываются только сделки, объем которых превышал пороговый (т.е. крупняк бил в крупняк).
-- isHugeBid, isHugeOfr (boolean) - флаги на текущий момент. 
-- t_S - время последнего изменения полей sumV_S или maxQ_Bid. 
tStakan = {};

-- Таблицы содержат количества попадания соответственно sumV_S и sumV_B (именно наоборот!) в интервалы описанные функцией my_math.NOfInterval(n).
-- Для каждого инструмента с кодом sec_code имеем массив (именно массив а не таблицу) с частотами.
tFreq_B={}; -- За сегодняшний день
tFreq_S={};
tFreqPrev_B={}; -- За предыдущий рабочий день
tFreqPrev_S={};

for s_c, val in pairs(tVars) do
	val.lastP_B = 0; 
	val.lastP_S = 0;
	val.last_oper = 0;
	val.last_t_mcs = 0;
	val.seria_sumMktV = 0;
	val.seria_sumBigLimV = 0;
	val.seria_lastLevSumV = 0;
    val.seria_maxLevSumV = 0;
	val.seria_maxLevP = 0;
	val.seria_p0 = 0;
	val.seria_p1 = 0;
	val.seria_t = 0;
	val.auto_B = false;
	val.auto_S = false;
	val.DAYS_TO_MAT_DATE = tonumber(getParamEx("SPBFUT", val.fut_sec_code, "DAYS_TO_MAT_DATE").param_value);
	val.GO = tonumber(getParamEx("SPBFUT", val.fut_sec_code, "BUYDEPO").param_value);
	val.lot_size = tonumber(getSecurityInfo ("SPBFUT", val.fut_sec_code).lot_size);

	tStakan[s_c] = {};
	tActLev_B[s_c] = {};
	tActLev_S[s_c] = {};
	
	tFreq_B[s_c] = {};
	tFreq_S[s_c] = {};
	tFreqPrev_B[s_c] = {};
	tFreqPrev_S[s_c] = {};
	for i=1,37,1 do
		tFreq_B[s_c][i]=0;
		tFreq_S[s_c][i]=0;
	end
end
--========================================================================================
function ClearLogForToday()
	local t = LOCALTIMEToTable(getInfoParam("LOCALTIME"));
	local d = getTradeDate();
	local sec_code;
	local s;
	local arr;
	local newFileIsEmpty;
	
	if t.hour<10 then return; end
	
	local ND_ago = WorkDaysMinus(d, TodDayOfWeek(), 3);
	--message("3 days ago= "..ND_ago.day.."."..ND_ago.month.."."..ND_ago.year,1);
	
	for sec_code, _ in pairs(tVars) do
		f = io.open("c:\\"..sec_code..".log", "a+");
		f1 = io.open("c:\\"..sec_code.."_temp.log", "w+");
		newFileIsEmpty = true;
		repeat
			s=f:read();
			arr=parseString(s, ";");
			
			if type(arr)=="table" and #arr>0 and arr[1]~=DatetimeToYYYYMMDD(d) then
				if not newFileIsEmpty then
					f1:write("\n");
				else
					newFileIsEmpty = false;
				end
				f1:write(s);
			end
		until s==nil
		f:close();
		f1:close();
		os.remove("c:\\old_"..sec_code..".log");
		os.rename("c:\\"..sec_code..".log", "c:\\old_"..sec_code..".log");
		os.rename("c:\\"..sec_code.."_temp.log", "c:\\"..sec_code..".log");
	end
end
--========================================================================================
function OnEndOfDaySession()
	local lev_p;
	local tLevB;
	local tLevS;
	local sec_code;
	local tSt;
	
	if isDaySessionFinished then
		return;
	end
	
	local t = LOCALTIMEToTable(getInfoParam("LOCALTIME"));
	local d = getTradeDate();
	if (t.hour==18 and t.min>40) or t.hour>18 then
		isDaySessionFinished = true;
		WriteFreqLog();
		for sec_code, _ in pairs(tVars) do
			if tVars[sec_code].class_code=="TQBR" then
				tLevB = tActLev_B[sec_code];
				tLevS = tActLev_S[sec_code];
				tSt = tStakan[sec_code];
				--Обновляем tActLev_B:
				for lev_p, _ in pairs(tLevB) do
					WriteLog(sec_code, DatetimeToYYYYMMDD(d)..";"..delDelimiterFromString(tSt[lev_p].t_S, ":")..";"..tostring(lev_p)..";"..tostring(tSt[lev_p].sumV_S)..";"..tostring(tSt[lev_p].sumBigV_S)..";B");
					tLevB[lev_p] = nil;
				end
				--Обновляем tActLev_S:
				for lev_p, _ in pairs(tLevS) do
					WriteLog(sec_code, DatetimeToYYYYMMDD(d)..";"..delDelimiterFromString(tSt[lev_p].t_B, ":")..";"..tostring(lev_p)..";"..tostring(tSt[lev_p].sumV_B)..";"..tostring(tSt[lev_p].sumBigV_B)..";S");
					tLevS[lev_p] = nil;
				end
			end
		end
	end
end
--========================================================================================
function NearestActLev(sec_code, oper)
	local class_code = tVars[sec_code].class_code;
	local bid;
	local ofr;
	bid, ofr = getBestBidOffer(class_code, sec_code);
	local tLev = IIF(oper=='B', tActLev_B[sec_code], tActLev_S[sec_code]);
	local nearest_lev = IIF(oper=='B', 0, 1000000);
	
	for lev_p, _ in pairs(tLev) do
		nearest_lev = IIF(oper=='B', math.max(nearest_lev,IIF(lev_p<=bid,lev_p,0)), math.min(nearest_lev,IIF(lev_p>=ofr,lev_p,1000000)));
	end

	if nearest_lev==0 or nearest_lev==1000000 then return nil; 
	else return nearest_lev;
	end
end
--========================================================================================
function TVSChanged() -- Сканирует ТВС в квике и обновляет в tStakan поля sumV
	local tTVS;
	local newLastTVS_i=getNumberOf("all_trades");
	local p;
	local q;
	local big_q; -- Если q > thrV, то big_q = q, иначе big_q = 0.
	local t;
	local sCode;
	local tSt; -- tStakan[sCode]
	local tSt_p; -- tStakan[sCode][p]
	local lastP_B;
	local lastP_S;
	local thrV;
	local tLevB;
	local tLevS;
	local lot_size;
	local j;
	local x;
	local oper;
	
	for i=lastTVS_i, (newLastTVS_i-1), 1 do
		tTVS = getItem ("all_trades", i);
		
		if tTVS and tVars[tTVS.sec_code] and ( ("TQBR"==tTVS.class_code and IsDaySession(tTVS.datetime.hour,tTVS.datetime.min)) or "CETS"==tTVS.class_code) then
			oper = IIF(tonumber(tTVS.flags)==1, "S", "B");
			sCode = tTVS.sec_code;
			tSt = tStakan[sCode];
			lastP_B, lastP_S = tVars[sCode].lastP_B, tVars[sCode].lastP_S;
			thrV = tVars[sCode].thrV;
			tLevB = tActLev_B[sCode];
			tLevS = tActLev_S[sCode];
			lot_size = tVars[sCode].lot_size;
			t = tTVS.datetime.hour..":"..IIF(tonumber(tTVS.datetime.min)<10, "0", "")..tTVS.datetime.min;
			p, q, big_q = tonumber(tTVS.price), tonumber(tTVS.qty), IIF(tonumber(tTVS.qty) > thrV, tonumber(tTVS.qty), 0);
			if tSt[p]==nil then -- -- записи по такой цене в tSt еще НЕ существует:
				tSt[p] = {["maxQ_Ofr"]=0, ["maxQ_Bid"]=0, ["sumV_B"]=0, ["sumV_S"]=0, ["sumBigV_B"]=0, ["sumBigV_S"]=0, ["t_S"]=0, ["t_B"]=0};
			end			
			tSt_p = tSt[p];
			
			-- Анализ последней СЕРИИ сделок: посмотрим не закончился ли большой рыночный ордер:
			if tVars[sCode].last_oper==oper and tVars[sCode].last_t_mcs==tTVS.datetime.mcs then -- Серия сделок продолжается:
				tVars[sCode].seria_sumMktV = tVars[sCode].seria_sumMktV + q;
				if (oper=='B' and lastP_B==p) or (oper=='S' and lastP_S==p) then -- Цена сделки не изменилась:
					tVars[sCode].seria_lastLevSumV = tVars[sCode].seria_lastLevSumV + q;
				else -- Цена сделки изменилась:
					tVars[sCode].seria_lastLevSumV = q;
				end
				if tVars[sCode].seria_lastLevSumV > tVars[sCode].seria_maxLevSumV then
					tVars[sCode].seria_maxLevSumV = tVars[sCode].seria_lastLevSumV;
					tVars[sCode].seria_maxLevP = p;
				end
			else -- Началась новая серия сделок:
				if tVars[sCode].seria_sumMktV>thrV then -- Закончившаяся серия сделок была большой и ее нужно напечатать
					local p_step = 1/math.pow(10,tonumber(getSecurityInfo(tTVS.class_code, sCode).scale)); -- Шаг цены спота.
					local isSizeHunting = false;
					if tVars[sCode].seria_maxLevSumV>thrV and math.abs(tVars[sCode].seria_maxLevP - tVars[sCode].seria_p1)<=4*p_step and math.abs(tVars[sCode].seria_maxLevP - tVars[sCode].seria_p0)<=4*p_step then
						isSizeHunting = true;
					end
					PrintMktSeria(sCode, tVars[sCode].seria_t, tVars[sCode].last_oper, tVars[sCode].seria_p0, tVars[sCode].seria_p1, tVars[sCode].seria_sumMktV, tVars[sCode].seria_maxLevSumV, isSizeHunting);
					DrawMktSeria(sCode, tVars[sCode].last_oper, tVars[sCode].seria_t, tVars[sCode].seria_p0, tVars[sCode].seria_p1, tVars[sCode].seria_sumBigLimV, tVars[sCode].seria_sumMktV);
				end
				tVars[sCode].seria_t = t;
				tVars[sCode].seria_sumMktV = q;
				tVars[sCode].last_oper = oper;
				tVars[sCode].last_t_mcs = tTVS.datetime.mcs
				tVars[sCode].seria_sumBigLimV = 0;
				tVars[sCode].seria_p0 = p;
				tVars[sCode].seria_lastLevSumV = q;
				tVars[sCode].seria_maxLevSumV = q;
				tVars[sCode].seria_maxLevP = p;
			end
			tVars[sCode].seria_p1 = p;
			if q>thrV then
				tVars[sCode].seria_sumBigLimV = tVars[sCode].seria_sumBigLimV + q;
			end
			
			--Обновляем tActLev_B:
			for lev_p, reach_p in pairs(tLevB) do
				if p>reach_p then -- обновим поле pft в квиковской таблице:
					local pft = math.floor(lot_size*p - lot_size*lev_p + 0.5);
					SetPft(sCode, lev_p, 'B', pft);
					tLevB[lev_p] = p;
				end
				if p<lev_p or (p==lev_p and oper=="B") then -- Удалим уровень т.к. его съели
					WriteLog(sCode, DatetimeToYYYYMMDD(tTVS.datetime)..";"..delDelimiterFromString(tSt[lev_p].t_S, ":")..";"..tostring(lev_p)..";"..tostring(tSt[lev_p].sumV_S)..";"..tostring(tSt[lev_p].sumBigV_S)..";B");
					PrintRealBigLimitBroken(sCode, lev_p, 'B');
					EraseRealBigLimit(sCode, 'B', lev_p);
					if lastTVS_i>1 then	SayLevelBroken(sCode,'B');	end
					tLevB[lev_p] = nil;
				end
			end
			
			--Обновляем tActLev_S:
			for lev_p, reach_p in pairs(tLevS) do
				if p<reach_p then -- обновим поле pft в квиковской таблице:
					local pft = math.floor(lot_size*lev_p - lot_size*p + 0.5);
					SetPft(sCode, lev_p, 'S', pft);
					tLevS[lev_p] = p;
				end
				if p>lev_p or (p==lev_p and oper=="S") then  -- Удалим уровень т.к. его съели
					WriteLog(sCode, DatetimeToYYYYMMDD(tTVS.datetime)..";"..delDelimiterFromString(tSt[lev_p].t_B, ":")..";"..tostring(lev_p)..";"..tostring(tSt[lev_p].sumV_B)..";"..tostring(tSt[lev_p].sumBigV_B)..";S");
					PrintRealBigLimitBroken(sCode, lev_p, 'S');
					EraseRealBigLimit(sCode, 'S', lev_p);
					if lastTVS_i>1 then	SayLevelBroken(sCode,'S');	end
					tLevS[lev_p] = nil;
				end
			end

			-- Обновляем tStakan:
			if oper=="S" then -- Сделка SELL
			
				-- Корректируем биды:
				if p > lastP_S then -- бид повысился с момента последней продажи.
					tSt_p.sumV_S, tSt_p.sumBigV_S, tSt_p.t_S = q, big_q, t;
				else -- p <= lastP_S
					tSt_p.sumV_S, tSt_p.sumBigV_S, tSt_p.t_S = tSt_p.sumV_S + q, tSt_p.sumBigV_S + big_q,  t;
					if p < lastP_S and tSt[lastP_S] then  -- бид понизился с момента последней продажи. Предыд. бид съели.
						x = NOfInterval(tSt[lastP_S].sumV_S);
						tFreq_B[sCode][x] = tFreq_B[sCode][x] + 1;
						tSt[lastP_S].sumV_S, tSt[lastP_S].sumBigV_S, tSt[lastP_S].maxQ_Bid, tSt[lastP_S].t_S = 0, 0, 0, t;
					end
				end
				
				-- Корректируем оффера:
				if p >= lastP_B and tSt[lastP_B] then -- съели оффер
					x = NOfInterval(tSt[lastP_B].sumV_B);
					tFreq_S[sCode][x] = tFreq_S[sCode][x] + 1;
					tSt[lastP_B].sumV_B, tSt[lastP_B].sumBigV_B, tSt[lastP_B].maxQ_Ofr, tSt[lastP_B].t_B  = 0, 0, 0, t;
				end
				
				-- Объем превышает порог:
				if tSt_p.sumV_S > thrV then
					local isIceberg = false;
					if tSt_p.maxQ_Bid < thrV/2 and tSt_p.maxQ_Bid>0 then isIceberg=true; end
					if tLevB[p]==nil then tLevB[p] = p; end
					PrintRealBigLimit(sCode, 'B', p, isIceberg);
					DrawRealBigLimit(sCode, 'B', t, p, tSt_p.sumV_S, tSt_p.sumBigV_S);
				end
				tVars[sCode].lastP_S = p;
			else -- Сделка BUY
			
				-- Корректируем оффера:
				if p < lastP_B then -- оффер понизился с момента последней покупки.
					tSt_p.sumV_B, tSt_p.sumBigV_B, tSt_p.t_B = q, big_q, t;
				else -- p >= lastP_B
					tSt_p.sumV_B, tSt_p.sumBigV_B, tSt_p.t_B = tSt_p.sumV_B + q, tSt_p.sumBigV_B + big_q, t;
					if p > lastP_B and tSt[lastP_B] then -- оффер повысился с момента последней покупки.
						x = NOfInterval(tSt[lastP_B].sumV_B);
						tFreq_S[sCode][x] = tFreq_S[sCode][x] + 1;
						tSt[lastP_B].sumV_B, tSt[lastP_B].sumBigV_B, tSt[lastP_B].maxQ_Ofr, tSt[lastP_B].t_B = 0, 0, 0, t;
					end
				end
				
				-- Корректируем биды:
				if p <= lastP_S and tSt[lastP_S] then -- съели бид.
					x = NOfInterval(tSt[lastP_S].sumV_S);
					tFreq_B[sCode][x] = tFreq_B[sCode][x] + 1;
					tSt[lastP_S].sumV_S, tSt[lastP_S].sumBigV_S, tSt[lastP_S].maxQ_Bid, tSt[lastP_S].t_S  = 0, 0, 0, t;
				end
				
				-- Объем превышает порог:
				if tSt_p.sumV_B > thrV then
					local isIceberg = false;
					if tSt_p.maxQ_Ofr < thrV/2 and tSt_p.maxQ_Ofr>0 then isIceberg=true; end
					if tLevS[p]==nil then tLevS[p] = p; end
					PrintRealBigLimit(sCode, 'S', p, isIceberg);
					DrawRealBigLimit(sCode, 'S', t, p, tSt_p.sumV_B, tSt_p.sumBigV_B);
				end
				tVars[sCode].lastP_B = p;
			end
		end
	end
	lastTVS_i = newLastTVS_i;
end
--========================================================================================
function StakanChanged() -- Сканирует стакан в квике и обновляет в tStakan поля maxV
	local stakan;
	local p;
	local q;
	local tSt_p; -- tStakan[sec_code][p]
	local thrV;
	
	for sec_code, val in pairs(tVars) do
		stakan = getQuoteLevel2(val.class_code, sec_code);
		thrV = tVars[sec_code].thrV;
		
		if tonumber(stakan.bid_count)>1 then
			for i=1, tonumber(stakan.bid_count), 1 do
				p, q = tonumber(stakan.bid[i].price), tonumber(stakan.bid[i].quantity);
				tSt_p = tStakan[sec_code][p];
				
				if tSt_p then
					tSt_p.maxQ_Bid = math.max(tonumber(tSt_p.maxQ_Bid), q);
					tSt_p.Q_Bid, tSt_p.Q_Ofr = q, 0;
				else
					tStakan[sec_code][p]={maxQ_Bid=q, maxQ_Ofr=0, sumV_B=0, sumV_S=0, sumBigV_B=0, sumBigV_S=0, Q_Bid=q, Q_Ofr=0, t_S=0, t_B=0};
				end
				
				if q > 3*thrV then
					if not tStakan[sec_code][p].isHugeBid then
						tStakan[sec_code][p].isHugeBid = true;
						PrintExpectedBigLimit(sec_code, 'B', p);
						DrawExpectedBigLimit(sec_code, 'B', p, q);
						if q > 5*thrV then SayVeryHugeBid(sec_code); else SayHugeBid(sec_code); end
					end
				else
					tStakan[sec_code][p].isHugeBid = false;
				end
			end

			for i=1, tonumber(stakan.offer_count), 1 do
				p, q = tonumber(stakan.offer[i].price), tonumber(stakan.offer[i].quantity);
				tSt_p = tStakan[sec_code][p];
				
				if tSt_p then
					tSt_p.maxQ_Ofr=math.max(tonumber(tSt_p.maxQ_Ofr), q);
					tSt_p.Q_Bid, tSt_p.Q_Ofr = 0, q;
				else 
					tStakan[sec_code][p]={maxQ_Bid=0, maxQ_Ofr=q, sumV_B=0, sumV_S=0, sumBigV_B=0, sumBigV_S=0, Q_Bid=0, Q_Ofr=q, t_S=0, t_B=0};
				end
				
				if q > 3*thrV then
					if not tStakan[sec_code][p].isHugeOffer then
						PrintExpectedBigLimit(sec_code, 'S', p);
						DrawExpectedBigLimit(sec_code, 'S', p, q);
						tStakan[sec_code][p].isHugeOffer = true;
						if q > 5*thrV then SayVeryHugeOffer(sec_code); else SayHugeOffer(sec_code);	end
					end
				else
					tStakan[sec_code][p].isHugeOffer = false;
				end
			end
		end
	end
	
	RefreshWndCaptions();
end
--========================================================================================
function WriteLog(sec_code, str)
	local fsize;
	
	f = io.open("c:\\"..sec_code..".log", "a");
	fsize = f:seek("end");
	if fsize>0 then f:write("\n"); end
	f:write(tostring(str));
	f:close();
end
--========================================================================================
function ReadFreqLog()
	local f;
	local sec_code;
	local s="";
	local arr;
	local arr_B;
	local arr_S;
	local d = getTradeDate();
	local total_lev;
	local thr;
	local x;
	
	for sec_code, _ in pairs(tVars) do
		f = io.open("c:\\freq_"..sec_code..".log");
		
		s = f:read();
		arr_B, arr_S = nil, nil;
		while s do
			arr = parseString(s, ";");
			if type(arr)=="table" and #arr==39 and arr[1]~=DatetimeToYYYYMMDD(d) then
				if arr[2]=='B' then arr_B = arr; else arr_S = arr; end
			end
			s = f:read();
		end
		
		if arr_B then
			total_lev = 0;
			for i=3,39,1 do	
				total_lev = total_lev + arr_B[i];
				tFreqPrev_B[sec_code][i-2] = arr_B[i];
			end
			x=0;
			for i=3,39,1 do	
				x = x + arr_B[i];
				if x>total_lev*tVars[sec_code].thrVInP then
					_,x = BordersOfInterval(i-2);
					break;
				end
			end
		end
			
		f:close();
	end
end
--========================================================================================
function WriteFreqLog()
	local fsize;
	local str;
	local d = getTradeDate();
	local t = LOCALTIMEToTable(getInfoParam("LOCALTIME"));
	if t.hour<10 then return; end
	local sec_code;
	local arr;
	local newFileIsEmpty;
	local f;
	local f1;
	
	
	for sec_code, _ in pairs(tVars) do
		-- Очистим лог-файл от сегодняшних записей:
		f = io.open("c:\\freq_"..sec_code..".log", "a+");
		f1 = io.open("c:\\freq_"..sec_code.."_temp.log", "w+");
		newFileIsEmpty = true;
		repeat
			str=f:read();
			arr=parseString(str, ";");
			
			if type(arr)=="table" and #arr>0 and arr[1]~=DatetimeToYYYYMMDD(d) then
				if not newFileIsEmpty then
					f1:write("\n");
				else
					newFileIsEmpty = false;
				end
				f1:write(str);
			end
		until str==nil
		f:close();
		f1:close();
		os.remove("c:\\old_freq_"..sec_code..".log");
		os.rename("c:\\freq_"..sec_code..".log", "c:\\old_freq_"..sec_code..".log");
		os.rename("c:\\freq_"..sec_code.."_temp.log", "c:\\freq_"..sec_code..".log");
		
		-- Запишем сегодняшние данные:
		f = io.open("c:\\freq_"..sec_code..".log", "a");
		fsize = f:seek("end");
		if fsize>0 then f:write("\n"); end
		str = DatetimeToYYYYMMDD(d)..";B";
		for i=1,#(tFreq_B[sec_code]),1 do
			str = str..";"..ToStr(tFreq_B[sec_code][i]); 
		end
		f:write(tostring(str));
		str = "\n"..DatetimeToYYYYMMDD(d)..";S";
		for i=1,#(tFreq_S[sec_code]),1 do
			str = str..";"..ToStr(tFreq_S[sec_code][i]); 
		end
		f:write(tostring(str));
		f:close();
	end
end
--========================================================================================
function sendClosePosition(sec_code) -- Закрывает "по рынку" текущую позицию по инструменту.
	local fut_sec_code = tVars[sec_code].fut_sec_code;
	fut_bid, fut_ofr = getBestBidOffer("SPBFUT", fut_sec_code);
	local err;
	
	local cur_pos = getPos(fut_sec_code); -- открытая позицию по нашему фьючерсу.
	
	if cur_pos>0 then -- закрываем лонг:
		err,_ = sendLimitOrder("SPBFUT", fut_sec_code, 'S', fut_bid-25, cur_pos);
	elseif cur_pos<0 then -- закрываем шорт:
		err,_ = sendLimitOrder("SPBFUT", fut_sec_code, 'B', fut_ofr+25, -cur_pos);
	end
end
--========================================================================================
function sendOpenPosition(sec_code, oper) -- Открывает "по рынку" максимальную позицию по инструменту.
	local fut_sec_code = tVars[sec_code].fut_sec_code;
	fut_bid, fut_ofr = getBestBidOffer("SPBFUT", fut_sec_code);
	local err;
	
	if oper=='B' then -- открываем лонг:
		err,_ = sendLimitOrder("SPBFUT", fut_sec_code, 'B', fut_ofr+25, tVars[sec_code].my_size);
	elseif oper=='S' then -- открываем шорт:
		err,_ = sendLimitOrder("SPBFUT", fut_sec_code, 'S', fut_bid-25, tVars[sec_code].my_size);
	end
end
--========================================================================================
function sendAutoOrder(sec_code, oper) -- Ищет оптимальную точку для лимитки и выставляет его на my_size. sec_code - это спот, т.е. ключ для tVars.
	local fut_sec_code = tVars[sec_code].fut_sec_code;
	fut_bid, fut_ofr = getBestBidOffer("SPBFUT", fut_sec_code);
	local err;

	local tCan; -- Последние несколько свечек фьючерса
	tCan,_,_ = getCandlesByIndex (tVars[sec_code].fut_chart_lbl, 0, getNumCandles(tVars[sec_code].fut_chart_lbl)-5, 5);
	local tCanLow = math.min(tCan[0].low, tCan[1].low, tCan[2].low, tCan[3].low, tCan[4].low);
	local tCanHigh = math.max(tCan[0].high, tCan[1].high, tCan[2].high, tCan[3].high, tCan[4].high);
	
	if oper=='B' then -- Выставить лимитку на покупку
		err,_ = sendLimitOrder("SPBFUT", fut_sec_code, 'B', math.min(fut_bid, tCanLow+2), tVars[sec_code].my_size);
	elseif oper=='S' then -- Выставить лимитку на продажу
		err,_ = sendLimitOrder("SPBFUT", fut_sec_code, 'S', math.max(fut_ofr, tCanHigh-2), tVars[sec_code].my_size);
	end
end
--========================================================================================
function sendAutoStop(sec_code, oper) -- Ищет оптимальную точку для стопа и выставляет на my_size. sec_code - это спот, т.е. ключ для tVars.
	local fut_sec_code = tVars[sec_code].fut_sec_code;
	local fut_bid;
	local fut_ofr;
	local class_code = tVars[sec_code].class_code;
	local p_step = 1/math.pow(10,tonumber(getSecurityInfo(class_code, sec_code).scale)); -- Шаг цены спота.
	fut_bid, fut_ofr = getBestBidOffer("SPBFUT", fut_sec_code);
	local tSt = tStakan[sec_code]; -- Соответствующий стакан спота tStakan.
	local p_level;
	local p;
	local thr=tVars[sec_code].thrV;
	local err;
	
	if oper=='B' then -- Выставить стоп-лосс на покупку
		p_level = NearestActLev(sec_code, 'S');
		if p_level then
			p = IIF(tSt[p_level + p_step] and tSt[p_level + p_step].sumV_B > thr, p_level + p_step, p_level);
			p_level = IIF(tSt[p_level + 2*p_step] and tSt[p_level + 2*p_step].sumV_B > thr, p_level + 2*p_step, p_level);
			p_level = math.max(p, p_level);
			err,_ = sendStopOrderByAnother("SPBFUT", fut_sec_code, tVars[sec_code].class_code, sec_code, 'B', fut_ofr+100, p_level+p_step, tVars[sec_code].my_size);
		else
			message("Error. sendAutoStop("..sec_code.."): Level for SL not found.",1);
		end
	elseif oper=='S' then -- Выставить стоп-лосс на продажу
		p_level = NearestActLev(sec_code, 'B');
		if p_level then
			p = IIF(tSt[p_level - p_step] and tSt[p_level - p_step].sumV_S > thr, p_level - p_step, p_level);
			p_level = IIF(tSt[p_level - 2*p_step] and tSt[p_level - 2*p_step].sumV_S > thr, p_level - 2*p_step, p_level);
			p_level = math.min(p, p_level);
			err,_ = sendStopOrderByAnother("SPBFUT", fut_sec_code, tVars[sec_code].class_code, sec_code, 'S', fut_bid-100, p_level-p_step, tVars[sec_code].my_size);
		else
			message("Error. sendAutoStop("..sec_code.."): Level for SL not found.",1);
		end
	end
end
--========================================================================================
function OnClose()
	EraseAllLabels(sec_code);
	DestroyAllGUITables();
end
--========================================================================================
function OnStop(stop_flag)
	is_run=false;
	EraseAllLabels(sec_code);
	DestroyAllGUITables();
	--sleep(500);
	message("BYE",1);
end
--========================================================================================
function main()
	message("START",1);
	init_GUI();
	ReadFreqLog();
	ClearLogForToday();
    while is_run do
        sleep(1000);
	    StakanChanged();
	    TVSChanged();
		RefreshBoard();
		OnEndOfDaySession();
    end
end
