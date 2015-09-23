--========================================================================================
function SayVeryHugeBid(sec_code)
	if tQT[sec_code].isSoundOFF then return; end
	
	if sec_code=="SBER" then
		PlaySoundFile("C:\\k\\sounds\\my\\sber_very_huge_bid.wav");
	elseif sec_code=="LKOH" then
		PlaySoundFile("C:\\k\\sounds\\my\\lkoh_very_huge_bid.wav");
	elseif sec_code=="VTBR" then
		PlaySoundFile("C:\\k\\sounds\\my\\vtbr_very_huge_bid.wav");
	elseif sec_code=="GAZP" then
		PlaySoundFile("C:\\k\\sounds\\my\\gazp_very_huge_bid.wav");
	elseif sec_code=="USD000UTSTOM" then
		PlaySoundFile("C:\\k\\sounds\\my\\usdrub_very_huge_bid.wav");
	end
end
--========================================================================================
function SayVeryHugeOffer(sec_code)
	if tQT[sec_code].isSoundOFF then return; end
	
	if sec_code=="SBER" then
		PlaySoundFile("C:\\k\\sounds\\my\\sber_very_huge_ofr.wav");
	elseif sec_code=="LKOH" then
		PlaySoundFile("C:\\k\\sounds\\my\\lkoh_very_huge_ofr.wav");
	elseif sec_code=="VTBR" then
		PlaySoundFile("C:\\k\\sounds\\my\\vtbr_very_huge_ofr.wav");
	elseif sec_code=="GAZP" then
		PlaySoundFile("C:\\k\\sounds\\my\\gazp_very_huge_ofr.wav");
	elseif sec_code=="USD000UTSTOM" then
		PlaySoundFile("C:\\k\\sounds\\my\\usdrub_very_huge_ofr.wav");
	end
end
--========================================================================================
function SayHugeBid(sec_code)
	if tQT[sec_code].isSoundOFF then return; end
	
	if sec_code=="SBER" then
		PlaySoundFile("C:\\k\\sounds\\my\\sber_huge_bid.wav");
	elseif sec_code=="LKOH" then
		PlaySoundFile("C:\\k\\sounds\\my\\lkoh_huge_bid.wav");
	elseif sec_code=="VTBR" then
		PlaySoundFile("C:\\k\\sounds\\my\\vtbr_huge_bid.wav");
	elseif sec_code=="GAZP" then
		PlaySoundFile("C:\\k\\sounds\\my\\gazp_huge_bid.wav");
	elseif sec_code=="USD000UTSTOM" then
		PlaySoundFile("C:\\k\\sounds\\my\\usdrub_huge_bid.wav");
	end
end
--========================================================================================
function SayHugeOffer(sec_code)
	if tQT[sec_code].isSoundOFF then return; end
	
	if sec_code=="SBER" then
		PlaySoundFile("C:\\k\\sounds\\my\\sber_huge_ofr.wav");
	elseif sec_code=="LKOH" then
		PlaySoundFile("C:\\k\\sounds\\my\\lkoh_huge_ofr.wav");
	elseif sec_code=="VTBR" then
		PlaySoundFile("C:\\k\\sounds\\my\\vtbr_huge_ofr.wav");
	elseif sec_code=="GAZP" then
		PlaySoundFile("C:\\k\\sounds\\my\\gazp_huge_ofr.wav");
	elseif sec_code=="USD000UTSTOM" then
		PlaySoundFile("C:\\k\\sounds\\my\\usdrub_huge_ofr.wav");
	end
end
--========================================================================================
function SayLevelBroken(sec_code, oper)
	if tQT[sec_code].isSoundOFF then return; end
	
	if sec_code=="SBER" then
		if oper=='B' then PlaySoundFile("C:\\k\\sounds\\my\\sber_br_b.wav"); else PlaySoundFile("C:\\k\\sounds\\my\\sber_br_s.wav"); end
	elseif sec_code=="LKOH" then
		if oper=='B' then PlaySoundFile("C:\\k\\sounds\\my\\lkoh_br_b.wav"); else PlaySoundFile("C:\\k\\sounds\\my\\lkoh_br_s.wav"); end
	elseif sec_code=="VTBR" then
		if oper=='B' then PlaySoundFile("C:\\k\\sounds\\my\\vtbr_br_b.wav"); else PlaySoundFile("C:\\k\\sounds\\my\\vtbr_br_s.wav"); end
	elseif sec_code=="GAZP" then
		if oper=='B' then PlaySoundFile("C:\\k\\sounds\\my\\gazp_br_b.wav"); else PlaySoundFile("C:\\k\\sounds\\my\\gazp_br_s.wav"); end
	elseif sec_code=="USD000UTSTOM" then
		if oper=='B' then PlaySoundFile("C:\\k\\sounds\\my\\usdrub_br_b.wav"); else PlaySoundFile("C:\\k\\sounds\\my\\usdrub_br_s.wav"); end
	end
end
--========================================================================================
function SayNewLevel(sec_code, oper)
	if tQT[sec_code].isSoundOFF then return; end
	
	if sec_code=="SBER" then
		if oper=='B' then PlaySoundFile("C:\\k\\sounds\\my\\sber_b.wav"); else PlaySoundFile("C:\\k\\sounds\\my\\sber_s.wav"); end
	elseif sec_code=="LKOH" then
		if oper=='B' then PlaySoundFile("C:\\k\\sounds\\my\\lkoh_b.wav"); else PlaySoundFile("C:\\k\\sounds\\my\\lkoh_s.wav"); end
	elseif sec_code=="VTBR" then
		if oper=='B' then PlaySoundFile("C:\\k\\sounds\\my\\vtbr_b.wav"); else PlaySoundFile("C:\\k\\sounds\\my\\vtbr_s.wav"); end
	elseif sec_code=="GAZP" then
		if oper=='B' then PlaySoundFile("C:\\k\\sounds\\my\\gazp_b.wav"); else PlaySoundFile("C:\\k\\sounds\\my\\gazp_s.wav"); end
	elseif sec_code=="USD000UTSTOM" then
		if oper=='B' then PlaySoundFile("C:\\k\\sounds\\my\\usdrub_b.wav"); else PlaySoundFile("C:\\k\\sounds\\my\\usdrub_s.wav"); end
	end
end
--========================================================================================
