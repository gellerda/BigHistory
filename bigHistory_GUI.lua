COLOR_S = RGB(255,153,153);
COLOR_STRONG_S = RGB(255,51,51);
COLOR_B = RGB(153,255,153);
COLOR_STRONG_B = RGB(51,255,51);
COLOR_LIGHT_GREY = RGB(200,200,200);
COLOR_GREY = RGB(100,100,100);
COLOR_S2 = RGB(255, 110, 180);
COLOR_STRONG_S2 = RGB(255, 20, 147);
COLOR_B2 = RGB(127, 255, 212);
COLOR_STRONG_B2 = RGB( 0, 255, 127);
COLOR_YELLOW = RGB( 255, 255, 50);
--========================================================================================
function OperColor(oper, status) -- Возвращает цвет для данной операции и данного статуса
	if oper=='B' or oper=='B_MKT' or oper=='B_EXP' then
		return IIF(status==L_BROKEN, COLOR_B, COLOR_STRONG_B);
	elseif oper=='S' or oper=='S_MKT' or oper=='S_EXP' then
		return IIF(status==L_BROKEN, COLOR_S, COLOR_STRONG_S);
	end
end
--========================================================================================

-- tQT - таблица переменных, связанных с таблицами Квика. Ключом таблицы служит sec_code(string). 
-- Каждый элемент таблицы - таблица: tQT[sCode] = {t_id, lastBid, lastOfr, isSoundOFF, autoDrawON}

tQT = {};
t_id_Board = nil; -- Сводная таблица в Квике с текущей информацей для всех наших инструментов (вмен. ставка и т.д).

-- Таблицы, аналогичные tActLev_B, tActLev_S. 
-- tActive_X[sec_code][p] содержит идентифиувтор метки для этого активного уровня, ЕСЛИ ОНА НАРИСОВАНА.
-- Т.е. если autoDrawON==false, то эти массивы будут пусты.
tActLevLabels_B={};
tActLevLabels_S={};

--========================================================================================
function init_GUI() -- tSecs - любая таблица, ключом которой служат sec_code наших спот-инструментов
	local sec_code;
	local t_id;
	local i;
	local W=252;
	local H=130;
	local x_pos;
	local y_pos;
	
	for sec_code, _ in pairs(tVars) do
		tActLevLabels_B[sec_code]={};
		tActLevLabels_S[sec_code]={};
		tQT[sec_code] = { 
			["t_id"] = 0, ["lastHugeBid"] = 0, ["lastHugeOfr"] = 0, ["isSoundOFF"] = false, ["autoDrawON"] = false,
			["lastBid"] = 0, ["lastOfr"] = 0 -- последний активный бид/офер, который добавляли в t_id. Когда его съедают, переменная сбрасывается в ноль.
		};
	end
	
	t_id_Board = AllocTable();
	AddColumn (t_id_Board, 1, "name", true, QTABLE_STRING_TYPE, 18);
	AddColumn (t_id_Board, 2, "v_r", true, QTABLE_DOUBLE_TYPE  , 7);
	AddColumn (t_id_Board, 3, "fP-calc_fP", true, QTABLE_DOUBLE_TYPE  , 10);
	CreateWindow(t_id_Board);
	SetWindowPos(t_id_Board, 10, 10, 220, 120);
	SetWindowCaption(t_id_Board, "My data");
	
	for sec_code, _ in pairs(tQT) do
		InsertRow(t_id_Board, 1);
		SetCell(t_id_Board, 1, 1, sec_code);
	
		t_id = AllocTable();
		tQT[sec_code].t_id = t_id;
		
		if sec_code=="SBER" then
			i=1;
			x_pos = 1276-W;
			y_pos = 645;
		elseif sec_code=="GAZP" then
			i=1;
			x_pos = 1276;
			y_pos = 645;
		elseif sec_code=="LKOH" then
			i=2;
			x_pos = 1276;
			y_pos = 645+H;
		elseif sec_code=="VTBR" then
			i=2;
			x_pos = 1276-W;
			y_pos = 645+H;
		elseif sec_code=="USD000UTSTOM" then
			i=2;
			x_pos = 1276;
			y_pos = 645+H;
		end	
		
		AddColumn (t_id, 1, "t", true, QTABLE_TIME_TYPE, 7);
		AddColumn (t_id, 2, "P_0", true, QTABLE_INT_TYPE , 8);
		AddColumn (t_id, 3, "limV", true, QTABLE_INT_TYPE , 7);
		AddColumn (t_id, 4, "P_1", true, QTABLE_INT_TYPE , 8);
		AddColumn (t_id, 5, "mktV", true, QTABLE_INT_TYPE , 7);
		AddColumn (t_id, 6, "pft", true, QTABLE_INT_TYPE, 0);
		AddColumn (t_id, 7, "opr", true, QTABLE_STRING_TYPE, 0);
		CreateWindow(t_id);
		SetWindowPos(t_id, x_pos, y_pos, W, H);
		SetWindowCaption(t_id, sec_code);
		SetTableNotificationCallback(t_id, QuikTableCallback);
	end
end
--========================= SET COLOR ==============================================================
function SetColor_t(sec_code, row_i, b_col, txt_col, sel_b_col, sel_txt_col)
	SetColor(tQT[sec_code].t_id, row_i, 1, b_col, txt_col, sel_b_col, sel_txt_col);
end
--=======================
function SetColor_p0(sec_code, row_i, b_col, txt_col, sel_b_col, sel_txt_col)
	SetColor(tQT[sec_code].t_id, row_i, 2, b_col, txt_col, sel_b_col, sel_txt_col);
end
--=======================
function SetColor_limV(sec_code, row_i, b_col, txt_col, sel_b_col, sel_txt_col)
	SetColor(tQT[sec_code].t_id, row_i, 3, b_col, txt_col, sel_b_col, sel_txt_col);
end
--=======================
function SetColor_p1(sec_code, row_i, b_col, txt_col, sel_b_col, sel_txt_col)
	SetColor(tQT[sec_code].t_id, row_i, 4, b_col, txt_col, sel_b_col, sel_txt_col);
end
--=======================
function SetColor_mktV(sec_code, row_i, b_col, txt_col, sel_b_col, sel_txt_col)
	SetColor(tQT[sec_code].t_id, row_i, 5, b_col, txt_col, sel_b_col, sel_txt_col);
end
--=======================
function SetColor_profit(sec_code, row_i, b_col, txt_col, sel_b_col, sel_txt_col)
	SetColor(tQT[sec_code].t_id, row_i, 6, b_col, txt_col, sel_b_col, sel_txt_col);
end
--=======================
function SetColor_oper(sec_code, row_i, b_col, txt_col, sel_b_col, sel_txt_col)
	SetColor(tQT[sec_code].t_id, row_i, 7, b_col, txt_col, sel_b_col, sel_txt_col);
end
--========================= SET CELL ===============================================================
function SetCell_t(sec_code, row_i, t_str)
	SetCell(tQT[sec_code].t_id, row_i, 1, t_str);
end
--=======================
function SetCell_p0(sec_code, row_i, p_num)
	if p_num<1 then
		local arr=parseString(tostring(p_num), ".");
		SetCell(tQT[sec_code].t_id, row_i, 2, "."..arr[2], tonumber(p_num) );
	else
		SetCell(tQT[sec_code].t_id, row_i, 2, tostring(p_num), tonumber(p_num) );
	end
end
--=======================
function SetCell_limV(sec_code, row_i, limV_num)
	SetCell(tQT[sec_code].t_id, row_i, 3, FormatNumberForQT(limV_num), tonumber(limV_num) );
end
--=======================
function SetCell_p1(sec_code, row_i, p_num)
	if p_num<1 then
		local arr=parseString(tostring(p_num), ".");
		SetCell(tQT[sec_code].t_id, row_i, 4, "."..arr[2], tonumber(p_num) );
	else
		SetCell(tQT[sec_code].t_id, row_i, 4, tostring(p_num), tonumber(p_num) );
	end
end
--=======================
function SetCell_mktV(sec_code, row_i, mktV_num)
	SetCell(tQT[sec_code].t_id, row_i, 5, FormatNumberForQT(mktV_num), tonumber(mktV_num) );
end
--=======================
function SetCell_profit(sec_code, row_i, profit_num)
	SetCell(tQT[sec_code].t_id, row_i, 6, tostring(profit_num), tonumber(profit_num) );
end
--=======================
function SetCell_oper(sec_code, row_i, oper_str)
	SetCell(tQT[sec_code].t_id, row_i, 7, oper_str);
end
--======================== GET CELL ================================================================
function GetCell_t(sec_code, row_i)
	return GetCell(tQT[sec_code].t_id, row_i, 1);
end
--=======================
function GetCell_p0(sec_code, row_i)
	return GetCell(tQT[sec_code].t_id, row_i, 2);
end
--=======================
function GetCell_limV(sec_code, row_i)
	return GetCell(tQT[sec_code].t_id, row_i, 3);
end
--=======================
function GetCell_p1(sec_code, row_i)
	return GetCell(tQT[sec_code].t_id, row_i, 4);
end
--=======================
function GetCell_mktV(sec_code, row_i)
	return GetCell(tQT[sec_code].t_id, row_i, 5);
end
--=======================
function GetCell_profit(sec_code, row_i)
	return GetCell(tQT[sec_code].t_id, row_i, 6);
end
--=======================
function GetCell_oper(sec_code, row_i)
	return GetCell(tQT[sec_code].t_id, row_i, 7);
end
--========================================================================================
function RefreshBoard() -- Обновляет сводную таблицу t_id_Board
	local stakan;
	local fut_stakan;
	local p_spot;
	local p_fut;
	local p_fut_calc;
	local v_rate;
	local tN;
	local sec_code;
	
	tN, _ = GetTableSize(t_id_Board);
	for i=1,tN,1 do
		sec_code = GetCell(t_id_Board, i, 1).image;
		stakan = getQuoteLevel2(tVars[sec_code].class_code, sec_code);
		fut_stakan = getQuoteLevel2("SPBFUT", tVars[sec_code].fut_sec_code);
		
		if tonumber(stakan.bid_count)>1 then
			p_spot = tVars[sec_code].lot_size*(tonumber(stakan.bid[tonumber(stakan.bid_count)].price) + tonumber(stakan.offer[1].price))/2;
			p_fut = (tonumber(fut_stakan.bid[tonumber(fut_stakan.bid_count)].price) + tonumber(fut_stakan.offer[1].price))/2;
			v_rate = VmenStavka(p_fut, p_spot, tVars[sec_code].DAYS_TO_MAT_DATE);
			p_fut_calc = FutPriceAtVmenStavka(p_spot, tVars[sec_code].DAYS_TO_MAT_DATE, CURRENT_RATE);
			SetCell(t_id_Board, i, 2, FormatFloat(v_rate,1), tonumber(v_rate) );
			SetCell(t_id_Board, i, 3, FormatFloat(p_fut-p_fut_calc,0), tonumber(p_fut-p_fut_calc) );
		end
	end
end
--========================================================================================
function DrawMktSeria(sec_code, oper, t, p0, p1, limV, mktV) 
	-- t должно быть в формате "ЧЧ:ММ"
	-- oper передается обычной строкой. Вместо 'B' или 'S', можно передать 'B_MKT' или 'S_MKT'. Они считаются идентичны.
	if not tQT[sec_code].autoDrawON then return nil; end
	
	local label_params={};
	local arr;
	local d = getTradeDate ();
	local thr = tonumber(tVars[sec_code].thrV);
	
	--message("t="..t,1);
	arr = parseString(t, ":");
	label_params.TIME = arr[1]..arr[2].."00"; -- для label_params требуется форма времени ЧЧММ00 (минуты занулены).
	label_params.DATE = ConvertDateToYYYYMMDD(d.date);
	label_params.ALIGNMENT = "RIGHT";
	
	if oper=='B_MKT' or oper=='B' then
		label_params.HINT = t.." | Market BUY "..p0.."-"..p1.." V="..mktV.."  Opposit big sell limit V="..limV;
		if mktV>6*thr then label_params.IMAGE_PATH = "C:\\k\\pics\\green_dot3.bmp";
		elseif mktV>3*thr then label_params.IMAGE_PATH = "C:\\k\\pics\\green_dot2.bmp";
		else label_params.IMAGE_PATH = "C:\\k\\pics\\green_dot1.bmp"; 
		end
	elseif oper=='S_MKT' or oper=='S' then
		label_params.HINT = t.." | Market SELL "..p0.."-"..p1.." V="..mktV.."  Opposit big buy limit V="..limV;
		if mktV>6*thr then label_params.IMAGE_PATH = "C:\\k\\pics\\black_dot3.bmp";
		elseif mktV>3*thr then label_params.IMAGE_PATH = "C:\\k\\pics\\black_dot2.bmp";
		else label_params.IMAGE_PATH = "C:\\k\\pics\\black_dot1.bmp"; 
		end
	end

	local n_step = math.floor(math.abs(p1-p0)*100*tVars[sec_code].lot_size/tVars[sec_code].GO) + 1;
	local step = IIF(n_step<=1, p1-p0, (p1-p0)/n_step);
	for i=0,n_step,1 do
		label_params.YVALUE = p0 + i*step;
		AddLabel(tVars[sec_code].chart_lbl, label_params);
		-- message(sec_code.." p="..label_params.YVALUE,1);
	end
	
	label_params.IMAGE_PATH = "";
	label_params.TEXT = FormatNumberForQT(mktV);
	label_params.FONT_HEIGHT = 13;
	if oper=='B_MKT' or oper=='B' then
		label_params.YVALUE = p0 - tVars[sec_code].GO/tVars[sec_code].lot_size/100;
		label_params.R, label_params.G, label_params.B = 0,150,0;
	elseif oper=='S_MKT' or oper=='S' then
		label_params.YVALUE = p0 + 2*tVars[sec_code].GO/tVars[sec_code].lot_size/100;
		label_params.R, label_params.G, label_params.B = 200,0,0;
	end
	local lbl = AddLabel(tVars[sec_code].chart_lbl, label_params);
	--if sec_code=="VTBR" then message("WWW t="..ToStr(t).." lbl="..tostring(lbl).." Y="..label_params.YVALUE.." p0="..p0.." step="..step.." n_step="..n_step,1); end
end
--========================================================================================
function DrawRealBigLimit(sec_code, oper, t, p0, limV, mktV) 
	-- Если метка для данного лимитника уже нарисована, то обновит параметры метки.
	-- t должно быть в формате "ЧЧ:ММ"
	-- oper передается обычной строкой 'B' или 'S'.
	-- Возвращает идентификатор метки в случае успеха. Иначе - nil.
	if not tQT[sec_code].autoDrawON then return nil; end
	
	local label_params={};
	local arr;
	local d = getTradeDate ();
	local thr = tonumber(tVars[sec_code].thrV);
	
	arr = parseString(t, ":");
	label_params.TIME = arr[1]..arr[2].."00"; -- для label_params требуется форма времени ЧЧММ00 (минуты занулены).
	label_params.YVALUE = p0;
	label_params.DATE = ConvertDateToYYYYMMDD(d.date);
	label_params.ALIGNMENT = "RIGHT";
	
	if oper=='B' then
		label_params.HINT = t.." | "..p0.." | Limit BUY="..limV.."  Market SELL="..mktV;
		if limV>12*thr then label_params.IMAGE_PATH = "C:\\k\\pics\\green_line5.bmp";
		elseif limV>9*thr then label_params.IMAGE_PATH = "C:\\k\\pics\\green_line4.bmp";
		elseif limV>6*thr then label_params.IMAGE_PATH = "C:\\k\\pics\\green_line3.bmp";
		elseif limV>3*thr then label_params.IMAGE_PATH = "C:\\k\\pics\\green_line2.bmp";
		else label_params.IMAGE_PATH = "C:\\k\\pics\\green_line1.bmp"; 
		end
	elseif oper=='S' then
		label_params.HINT = t.." | "..p0.." | Limit SELL="..limV.." Market BUY="..mktV;
		if limV>12*thr then label_params.IMAGE_PATH = "C:\\k\\pics\\black_line5.bmp";
		elseif limV>9*thr then label_params.IMAGE_PATH = "C:\\k\\pics\\black_line4.bmp";
		elseif limV>6*thr then label_params.IMAGE_PATH = "C:\\k\\pics\\black_line3.bmp";
		elseif limV>3*thr then label_params.IMAGE_PATH = "C:\\k\\pics\\black_line2.bmp";
		else label_params.IMAGE_PATH = "C:\\k\\pics\\black_line1.bmp"; 
		end
	end
	if (oper=='B' and tActLevLabels_B[sec_code][p0]) or (oper=='S' and tActLevLabels_S[sec_code][p0]) then
		SetLabelParams(tVars[sec_code].chart_lbl, IIF(oper=='B',tActLevLabels_B[sec_code][p0],tActLevLabels_S[sec_code][p0]), label_params);
		return IIF(oper=='B',tActLevLabels_B[sec_code][p0],tActLevLabels_S[sec_code][p0]);
	else
		return AddLabel(tVars[sec_code].chart_lbl, label_params);
	end
end
--========================================================================================
function EraseRealBigLimit(sec_code, oper, p0) -- Удаляет с графика метку активного лимитного уровня, если она там есть. Если успешно - возвращает true;
	local r = false;
	
	if oper=='B' and tActLevLabels_B[sec_code][p0] then
		r = DelLabel(tVars[sec_code].chart_lbl, tActLevLabels_B[sec_code][p0]);
		if r then tActLevLabels_B[sec_code][p0] = nil; end
	elseif oper=='S' and tActLevLabels_S[sec_code][p0] then
		r = DelLabel(tVars[sec_code].chart_lbl, tActLevLabels_S[sec_code][p0]);
		if r then tActLevLabels_S[sec_code][p0] = nil; end
	end
	
	return r;
end
--========================================================================================
function EraseAllLabels(sec_code)
	if tActLevLabels_B[sec_code] then  tActLevLabels_B[sec_code] = {}; end
	if tActLevLabels_S[sec_code] then tActLevLabels_S[sec_code] = {}; end
	if tVars[sec_code] and tVars[sec_code].chart_lbl then DelAllLabels(tVars[sec_code].chart_lbl); end
end
--========================================================================================
function DrawExpectedBigLimit(sec_code, oper, p0, limV) 
	-- t должно быть в формате "ЧЧ:ММ"
	-- oper передается обычной строкой. Вместо 'B' или 'S', можно передать 'B_EXP' или 'S_EXP'. Они считаются идентичны.
	-- Возвращает идентификатор метки в случае успеха. Иначе - nil.
	if not tQT[sec_code].autoDrawON then return nil; end
	
	local label_params={};
	local arr;
	local d = getTradeDate ();
	local thr = tonumber(tVars[sec_code].thrV);
	local t = FormatTimeDelSecs(getInfoParam("LOCALTIME"));
	
	arr = parseString(t, ":");
	label_params.TIME = arr[1]..arr[2].."00"; -- для label_params требуется форма времени ЧЧММ00 (минуты занулены).
	label_params.YVALUE = p0;
	label_params.DATE = ConvertDateToYYYYMMDD(d.date);
	label_params.ALIGNMENT = "RIGHT";
	
	if oper=='B_EXP' or oper=='B' then
		label_params.HINT = t.." | "..p0.." | Limit BUY="..limV;
		label_params.IMAGE_PATH = "C:\\k\\pics\\green_dot1.bmp";
	elseif oper=='S_EXP' or oper=='S' then
		label_params.HINT = t.." | "..p0.." | Limit SELL="..limV;
		label_params.IMAGE_PATH = "C:\\k\\pics\\black_dot1.bmp";
	end
	return AddLabel(tVars[sec_code].chart_lbl, label_params);
end
--========================================================================================
function DrawAllLabels(sec_code) -- Рисует все метки на графике инструмента sec_code.
	if tQT[sec_code].autoDrawON==false then return nil; end
	
	local tN;
	tN, _ = GetTableSize(tQT[sec_code].t_id);
	local t;
	local p0;
	local p1;
	local limV;
	local mktV;
	local oper;
	local tActLev;

	-- Нарисуем все крупные рыночные серии, и все серые строки (ожидаемые лимитники).
	for i=1, tN, 1 do
		t, p0, p1, limV, mktV, oper = GetCell_t(sec_code, i), GetCell_p0(sec_code, i), GetCell_p1(sec_code, i), GetCell_limV(sec_code, i), GetCell_mktV(sec_code, i), GetCell_oper(sec_code, i); -- Не забываем что это таблицы.
		if oper.image=='B_EXP' or oper.image=='S_EXP' then -- Серая строка (лимитник показался в стакане, но не подтвержден сделками).
			DrawExpectedBigLimit(sec_code, oper.image, t.image, p0.value, limV.value);
		elseif oper.image=='B_MKT' or oper.image=='S_MKT' then -- Серия сделок по одному рыночному ордеру.
			DrawMktSeria(sec_code, oper.image, t.image, p0.value, p1.value, limV.value, mktV.value);
		end
	end

	-- Нарисуем все активные лимитные уровни:
	tActLev = tActLev_B[sec_code];
	for p, _ in pairs(tActLev) do
		tActLevLabels_B[sec_code][p]=DrawRealBigLimit(sec_code, 'B', tStakan[sec_code].t_S, p, tStakan[sec_code].sumV_S, tStakan[sec_code].sumBigV_S);
	end
	
	tActLev = tActLev_S[sec_code];
	for p, _ in pairs(tActLev) do
		tActLevLabels_S[sec_code][p]=DrawRealBigLimit(sec_code, 'S', tStakan[sec_code].t_B, p, tStakan[sec_code].sumV_B, tStakan[sec_code].sumBigV_B);
	end
end
--========================================================================================
function QuikTableCallback(t_id, msg, par1, par2)
	local cur_t=FormatTimeDelSecs(getInfoParam("LOCALTIME"));
	local s_auto="";
	local sec_code;
	for sCode, val in pairs(tQT) do -- Определим тикер для данной таблицы:
		if tQT[sCode].t_id==t_id then
			sec_code = sCode;
			break;
		end
	end
	
	--if msg==QTABLE_CHAR then
	--message("char="..par2,1);
	--end
	
	if msg==QTABLE_CHAR and par2==8 then -- BACKSPACE. Удаляем только серые строки!
		if GetCell_oper(sec_code, par1).image=='S_EXP' or GetCell_oper(sec_code, par1).image=='B_EXP'then
			DeleteRow(t_id, par1);
		end
	end
	
	if msg==QTABLE_CHAR and (par2==113 or par2==233 or par2==119 or par2==246) then -- Q (113 или 233) или W (119 или 246) 
		--message("char="..par2,1);
		if par2==113 or par2==233 then -- Q
			tVars[sec_code].auto_B = IIF(tVars[sec_code].auto_B, false, true); -- Инвертируем
		end

		if par2==119 or par2==246 then -- W
			tVars[sec_code].auto_S = IIF(tVars[sec_code].auto_S, false, true); -- Инвертируем
		end

		if tVars[sec_code].auto_B then
			s_auto = s_auto.."  B:ON";
		else
			s_auto = s_auto.."  B:OFF";
		end
		if tVars[sec_code].auto_S then
			s_auto = s_auto..", S:ON";
		else
			s_auto = s_auto..", S:OFF";
		end
		SetWindowCaption(t_id, cur_t.."  "..sec_code..s_auto);
	end
	
	if msg==QTABLE_CHAR and (par2==115 or par2==251) then -- S (115 или 251) включить/выключить звук
		tQT[sec_code].isSoundOFF = IIF(tQT[sec_code].isSoundOFF, false, true);
	elseif msg==QTABLE_CHAR and (par2==108 or par2==228) then -- L (108 или 228) включить метки (Labels)
		if tQT[sec_code].autoDrawON then 
			tQT[sec_code].autoDrawON = false;
			EraseAllLabels(sec_code);
		else 
			tQT[sec_code].autoDrawON = true;
			DrawAllLabels(sec_code); 
		end
	elseif msg==QTABLE_CHAR and (par2==45) then -- - (45) клавиша "минус" - выставить стоп-лосс на продажу
		sendAutoStop(sec_code, 'S');
	elseif msg==QTABLE_CHAR and (par2==61 or par2==43) then -- + (45) клавиша "плюс" - выставить стоп-лосс на покупку
		sendAutoStop(sec_code, 'B');
	elseif msg==QTABLE_CHAR and (par2==47) then -- / (45) клавиша "/" - выставить лимитку на покупку и стоп-лосс на продажу
		sendAutoOrder(sec_code, 'B');
		sendAutoStop(sec_code, 'S');
	elseif msg==QTABLE_CHAR and (par2==42) then -- * (42) клавиша "*" - выставить лимитку на продажу и стоп-лосс на покупку
		sendAutoOrder(sec_code, 'S');
		sendAutoStop(sec_code, 'B');
	elseif msg==QTABLE_CHAR and (par2==92) then -- | (92) клавиша "\" - закрыться по рынку
		sendClosePosition(sec_code);
	elseif msg==QTABLE_CHAR and (par2==250 or par2==93) then -- ] (250 или 93) клавиша "]" - открываем максимальный лонг по рынку
		sendOpenPosition(sec_code, 'B');
	elseif msg==QTABLE_CHAR and (par2==253 or par2==39) then -- э (253 или 39) клавиша "э" - открываем максимальный шорт по рынку
		sendOpenPosition(sec_code, 'S');
	end

end
--========================================================================================
function findQTableRow(sec_code, p, oper) -- В квиковской таблице для sec_code находит первую с конца строку с (p, oper). Возвращает nil или #строки.   
	local tN;
	tN, _ = GetTableSize(tQT[sec_code].t_id);
	for j=tN, 1, -1 do
		if GetCell_p0(sec_code, j).value==tonumber(p) and GetCell_oper(sec_code, j).image==oper then 
			return j; 
		end
	end
	return nil;
end
--========================================================================================
function FormatNumberForQT(n) --возвращает строку: "-" если n==0 или n=="-". "1-" tckb n<1000. floor(n/1000) если n>=1000.
	if tonumber(n)==0 or tostring(n)=="-" then return "-";
	elseif tonumber(n)<1000 then return "1-";
	else return tostring(math.floor(n/1000));
	end
end
--========================================================================================
function PrintMktSeria(sec_code, t, oper, p0, p1, sumMktV, sumBigLimV, isSizeHunting)
	local t_id = tQT[sec_code].t_id;
	local tN;
	tN, _ = GetTableSize(t_id);
	local tSt_p = tStakan[sec_code][p];
	local col;
	local thrV = tVars[sec_code].thrV;
	
	InsertRow(t_id, tN+1);
	if isSizeHunting then
		SetColor(t_id, tN+1, QTABLE_NO_INDEX, RGB(255,128,0), RGB(0,0,0), RGB(255,128,0), RGB(0,0,0) ); -- Оранжевый.
	else
		SetColor(t_id, tN+1, QTABLE_NO_INDEX, COLOR_YELLOW, RGB(0,0,0), COLOR_YELLOW, RGB(0,0,0) );
	end
	SetCell_t(sec_code, tN+1, t);
	SetCell_p0(sec_code, tN+1, p0);
	SetCell_p1(sec_code, tN+1, p1);
	SetCell_mktV(sec_code, tN+1, sumMktV);
	SetCell_limV(sec_code, tN+1, sumBigLimV);
	
	if oper=='B' then
		SetCell_oper(sec_code, tN+1, 'B_MKT');
		col = IIF(sumMktV > 5*thrV, COLOR_STRONG_B, COLOR_B);
	else -- oper=='S'
		SetCell_oper(sec_code, tN+1, 'S_MKT');
		col = IIF(sumMktV > 5*thrV, COLOR_STRONG_S, COLOR_S);
	end
	--SetColor_p1(sec_code, tN+1, col, RGB(0,0,0), col, RGB(0,0,0) );
	--SetColor_p0(sec_code, tN+1, col, RGB(0,0,0), col, RGB(0,0,0) );
	SetColor_mktV(sec_code, tN+1, col, RGB(0,0,0), col, RGB(0,0,0) );
end
--========================================================================================
function PrintRealBigLimitBroken(sec_code, p, oper) -- Устанавливает цвет пробитого уровня для всех строк с ценой p и операцией oper. И сбрасываем в ноль lastBid/lastOfr.
	local t_id = tQT[sec_code].t_id;
	local tN;
	tN, _ = GetTableSize(t_id);
	local col = OperColor(oper, L_BROKEN);
	
	if (oper=='B' and tQT[sec_code].lastBid==p) then tQT[sec_code].lastBid=0; end
	if (oper=='S' and tQT[sec_code].lastOfr==p) then tQT[sec_code].lastOfr=0; end

	for j=tN, 1, -1 do
		if GetCell_p0(sec_code, j).value==tonumber(p) and GetCell_oper(sec_code, j).image==oper then 
			SetColor(t_id, j, QTABLE_NO_INDEX, col, RGB(0,0,0), col, RGB(0,0,0) );
		end
	end
end
--========================================================================================
-- Для подтвержденного сделками (в ТВС) лимитника напечатает новую, ИЛИ ОБНОВИТ уже существующую строку в таблице для sec_code .
function PrintRealBigLimit(sec_code, oper, p, isIceberg) 
	local row_i;
	local t_id = tQT[sec_code].t_id;
	local tSt_p = tStakan[sec_code][p];
	local col = OperColor(oper, L_ACTIVE);
	
	if (oper=='B' and tQT[sec_code].lastBid==p) or (oper=='S' and tQT[sec_code].lastOfr==p) then
		row_i=findQTableRow(sec_code, p, oper);
	else
		row_i, _ = GetTableSize(t_id);
		row_i = row_i+1;
		InsertRow(t_id, row_i);
		if lastTVS_i>1 then	SayNewLevel(sec_code,oper);	end
	end
	
	if row_i==nil then return; end
	
	SetCell_t(sec_code, row_i, IIF(oper=="B", tSt_p.t_S, tSt_p.t_B) );
	SetCell_p0(sec_code, row_i, p);
	SetCell_limV(sec_code, row_i, IIF(oper=="B", tSt_p.sumV_S, tSt_p.sumV_B) );
	SetCell_mktV(sec_code, row_i, IIF(oper=="B", tSt_p.sumBigV_S, tSt_p.sumBigV_B) );
	SetCell_oper(sec_code, row_i, oper);
	SetColor(t_id, row_i, QTABLE_NO_INDEX, col, RGB(0,0,0), col, RGB(0,0,0) );
	if isIceberg then
		SetColor_limV(sec_code, row_i, RGB(255,255,255), RGB(0,0,0), RGB(255,255,255), RGB(0,0,0) ); -- Белый
	end
	if oper=='B' then
		if tonumber(tSt_p.sumBigV_S)>0 then
			SetColor_mktV(sec_code, row_i, COLOR_S, RGB(0,0,0), COLOR_S, RGB(0,0,0) );
		end
		if tActLev_B[sec_code][p] then
			local pft = math.floor((tActLev_B[sec_code][p]-p)*tVars[sec_code].lot_size + 0.5);
			SetCell_profit(sec_code, row_i, pft);
		end
		tQT[sec_code].lastBid = tonumber(p);
	else -- oper=='S'
		if tonumber(tSt_p.sumBigV_B)>0 then
			SetColor_mktV(sec_code, row_i, COLOR_B, RGB(0,0,0), COLOR_B, RGB(0,0,0) );
		end
		if tActLev_S[sec_code][p] then
			local pft = math.floor((p-tActLev_S[sec_code][p])*tVars[sec_code].lot_size + 0.5);
			SetCell_profit(sec_code, row_i, pft);
		end
		tQT[sec_code].lastOfr = tonumber(p);
	end
end			
--========================================================================================
-- Для показанного в стакане лимитника, но еще не подтвержденного сделками, напечатает строку в таблице для sec_code .
function PrintExpectedBigLimit(sec_code, oper, p) 
	local t_id = tQT[sec_code].t_id;
	local tN;
	tN, _ = GetTableSize(t_id);
	local tSt_p = tStakan[sec_code][p];
	local col;
	local thrV = tVars[sec_code].thrV;
	
	if (oper=='S' and p~=tQT[sec_code].lastHugeOfr) or (oper=='B' and p~=tQT[sec_code].lastHugeBid)then 
		InsertRow(t_id, tN+1);
		SetColor(t_id, tN+1, QTABLE_NO_INDEX, COLOR_GREY, RGB(0,0,0), COLOR_GREY, RGB(0,0,0) );
		SetCell_p0(sec_code, tN+1, p);
		SetCell_t(sec_code, tN+1, FormatTimeDelSecs(getInfoParam("LOCALTIME")));
		
		if oper=='B' then
			SetCell_oper(sec_code, tN+1, 'B_EXP');
			SetCell_limV(sec_code, tN+1, tSt_p.Q_Bid);
			col = IIF(tSt_p.Q_Bid > 5*thrV, COLOR_STRONG_B, COLOR_B);
			tQT[sec_code].lastHugeBid = tonumber(p);
		else -- oper=='S'
			SetCell_oper(sec_code, tN+1, 'S_EXP');
			SetCell_limV(sec_code, tN+1, tSt_p.Q_Ofr);
			col = IIF(tSt_p.Q_Ofr > 5*thrV, COLOR_STRONG_S, COLOR_S);
			tQT[sec_code].lastHugeOfr = tonumber(p);
		end
		SetColor_limV(sec_code, tN+1, col, RGB(0,0,0), col, RGB(0,0,0) );
		SetColor_p0(sec_code, tN+1, col, RGB(0,0,0), col, RGB(0,0,0) );
	end
end
--========================================================================================
function DestroyAllGUITables()
	for sCode, _ in pairs(tQT) do
		DestroyTable(tQT[sCode].t_id);
	end
	DestroyTable(t_id_Board);
end
--========================================================================================
-- Находит в таблице для sec_code запись по цене p и операцией oper, и обновляет поле pft:
function SetPft(sec_code, p, oper, pft)
	local j = findQTableRow(sec_code, p, oper);
	if j then
		SetCell_profit(sec_code, j, pft);
	end
end					
--========================================================================================
function RefreshWndCaptions()
	local str;
	for s_c, val in pairs(tQT) do
		str=s_c.."| thr="..FormatNumberForQT(tVars[s_c].thrV+1).." ("..ToStr(tVars[s_c].thrVInP*100).."%) "..IIF(val.isSoundOFF,", Snd:OFF",", Snd:ON");
		SetWindowCaption(tQT[s_c].t_id, str);
	end
end
--========================================================================================
--========================================================================================
--========================================================================================
--========================================================================================
--========================================================================================
--========================================================================================
--========================================================================================
--========================================================================================
