
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/*****************                                                                       *******************/
/****************                      Отчет по протоколу ОЛ                              ******************/
/*****************                                                                       *******************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/

/*идентификатор компа*/ *D - sony, Z - ГНЦ;
*Без предефайна оказывается не работает;
%let disk = .;

%macro what_OC;
%if &sysscpl = W32_7PRO %then 
	%do;
		%let disk = C:\Users\user\Documents\GitHub\AL; *sony;
	%end;
%else/*%if &sysscpl = "W32_7PRO" %then */ 
	%do;
		%let disk = Z:\AC\AL; *остальные;
	%end;
%mend;

%what_OC;

Libname regal "&disk.\SAS";* Библиотека данных;


%macro Eventan(dat,T,C,i,s,cl,f,for, ttl);
/*
dat -имя набора данных,
T - время,
C - индекс события/цензурирования,
i=0, если с индекс события,
i=1, если с индекс цензурирования.
s = пусто,если строится кривая выживаемости
s = F, если строится кривая накопленной вероятности
cl = cl,если показывать доверительный интервал
cl = пусто,если не показывать доверительный интервал
s = F, если строится кривая накопленной вероятности
f = фактор (страта) ЕСЛИ ПУСТО ТО БЕЗ СТРАТЫ
for = формат (1.0 для целочисленных значаний, когда нет специального формата)
ttl = заголовок
*/

data _null_; set &dat;
   length tit1 $256 tit2 $256;
*чтение лейболов;
tit1=vlabel(&T);
%if &f ne %then %do; tit2=vlabel(&f);%end;
   * положили лейбала в макропеременную;
   call symput('tt1',tit1);
   call symput('tt2',tit2);
output;
   stop;
   keep tit1 tit2;
run;
title1 &ttl;
title2 " зависимая:  &tt1 // фактор       :  &tt2";
ods graphics on;
ods exclude WilHomCov LogHomCov HomStats  Quartiles ; *ProductLimitEstimates;
proc lifetest data=&dat plots =(s( &s &cl))  method=pl ;
    %if &f ne %then %do; strata &f/test=logrank;
    id &f;format   &f &for;%end;
    time &T*&C(&i) ;
run;
ods graphics off;
%mend;


/***********************************************************************************************************/
/***********************************************************************************************************/
/*****************                                                                       *******************/
/****************                        Начало программы                                ******************/
/*****************                                                                       *******************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/


*восстановление реляций;
data regal.al_al;
	set regal.al_al;
	rename
		new_contact = pt_id; 
run;

data regal.al_pt;
	set regal.al_pt;
	rename
		contactid = pt_id; 
run;

data regal.al_ev;
	set regal.al_ev;
	rename
		new_contact = pt_id; 
run;



proc format;
    value new_diag_f 1 = "ОМЛ" 2 = "ОЛЛ" 3 = "ОПЛ" ; 
	value gendercode_f 1 = "М" 2 = "Ж";
	value inPr_f 1 = "включен в протокол" 0 = "НЕ вкл. в пр.";
	value yn_f 1 = "да" 0 = "нет";
run;




proc freq data=regal.al_al; 
	tables 
		new_diagname
		new_vidleyname
		new_diagfabname 
		new_diagmkbname
		new_etnosname 
		new_factorriskname 
		new_sibling
		; 
run;
/*
birthdate
contactid
description
emailaddress1
fullname
gendercode
gendercodename
middlename
new_city
new_cityname
new_code
new_consent
new_consentdate
new_consentname
new_datelastcontact
new_deathdate
new_deathreason
new_deathreasonname
new_diagnosis
new_diagnosisage
new_diagnosisdate
new_diagnosisname
new_doctor
new_doctorname
new_firstname
new_fo
new_lastname
new_lpu
new_lpuname
new_oms
new_pasport
new_patientstat
new_patientstatname
new_region
new_regionname
new_snils
ownerid
owneridname
*/


proc freq data=regal.al_al; 
	tables
		new_diagname* (new_vidleyname new_diagfabname new_diagmkbname)/nopercent nocol;
run;



proc freq data=regal.al_pt; 
	tables 
		gendercodename
		new_cityname
		new_consentname
		new_deathreasonname
		new_diagnosis
		new_diagnosisname
		new_doctorname
		new_fo
		new_lpuname
		new_patientstatname
		new_regionname
		owneridname
		;
run;

*-- сцепляем таблицы пациентов --;

proc sort data=regal.al_al;  *out=pat1; 
	by pt_id; 
run;

/*data regal.al_al; *pat11; */
/*	set regal.al_al; *pat1; */
/*	contactid=new_contact; */
/*run;*/

proc sort data=regal.al_pt; *out=pat2; 
	by pt_id;
run;

data regal.patall; 
	merge regal.al_al regal.al_pt;  *pat11pat2; 
	by pt_id; 
	if new_diagnosisage < 10 then new_diagnosisage=.;
	if new_lpuname='ФГБУ ГНЦ МЗСЦ РФ' then center='ГНЦ';
		else center='рег';
run;

*--------------------------------;

*---------- статистика -----------;
proc means data=regal.patall n median min max mean; 
	var new_diagnosisage; 
run;

proc means data=regal.patall n median min max mean; 
	var new_diagnosisage; 
	class center; 
run;


*proc freq data=patall; 
*	tables  (new_patientstatname new_diagname new_diagfabname new_diagmkb new_diagmkbname new_etnosname )*center/nopercent norow;
*run;

*proc print data=regal.al_ev label; 
*	var new_contactname new_event new_eventname new_event_date new_event_txt ; 
*run;



proc sort data=regal.al_ev; *out=ev1; 
	by pt_id; *by new_contact; 
run;


data regal.EvAn; 
	set regal.al_ev; 
	by pt_id;

	retain datdeath datlcont datrel alive rel;
	if first.pt_id then do; 
			datdeath=.; 
			datlcont=.; 
			datrel=.; 
			alive=1; 
			rel=0;
			inPr=0;
		end;

	if new_event=1 then do; inPr=1; end; 	*включеине в каой-либо протокол;
	if new_event=2 then do; datlcont=new_event_date;  end; 
	if new_event=4 then do; datrel=new_event_date; rel=1; end; 
	if new_event=5 then do; datdeath=new_event_date; alive=0; end; 
	if new_event=6 then do; datlcont=new_event_date;  end; 


	if last.pt_id then output;

	label
		datdeath='дата смерти' 
		datlcont='дата п.контакта' 
		datrel='дата рецидива' 
		alive='жив?' 
		rel='рецидив?'
		;
run;




/*	proc freq data=ev2; tables alive rel; run;*/
	
proc sort data=regal.EvAn; *out=ev1; 
	by pt_id; *by new_contact; 
run;


data regal.PatAllEv; 
	merge regal.PatAll (in=inp) regal.EvAn (in=ine); 
	by  pt_id; 
	ip=inp; 
	ie=ine; 
run;


*---- подготовка данных для событийного анализа ----;

/*    select (i_death);*/
/*        when (1) TLive = (date_death - pr_b)/30;*/
/*        when (0) TLive = (lastdate   - pr_b)/30;*/
/*        otherwise;*/
/*    end;*/

data regal.PatAllEv; 
	set regal.PatAllEv; 

    select (alive);
        when (0) TLive = (datdeath - new_diagnosisdate)/30;
        when (1) TLive = (datlcont - new_diagnosisdate)/30;
        otherwise;
    end;

run;

%eventan (regal.PatAllEv, TLive, alive, 1,,cl,,,"Общая выживаемость");
/*%eventan (&LN..new_pt, TLive, i_death, 0,,&y,new_normkariotipname,,"Стратификация по кариотипу. Выживаемость");*/

/*
Eventan(dat,T,C,i,s,cl,f,for, ttl)
dat - имя набора данных,
T   - время,
C   - индекс события/цензурирования,
i   - идетификатор 
	i = 0, если с индекс события,
	i = 1, если с индекс цензурирования.
s   - пусто,если строится кривая выживаемости
	s = F, если строится кривая накопленной вероятности
cl  - пусто,если не показывать доверительный интервал
	cl = cl, если показывать доверительный интервал
f   - фактор (страта) ЕСЛИ ПУСТО ТО БЕЗ СТРАТЫ
for - формат (1.0 для целочисленных значаний, когда нет специального формата)
ttl - заголовок
*/

/*proc sort data = regal.PatAllEv;*/
/*	by TLive;*/
/*run;*/
/**/
/*proc print data = regal.PatAllEv;*/
/*	var TLive FIO datdeath datlcont new_diagnosisdate;*/
/*run;*/


*---------------------------------------------------;




proc freq data=regal.PatAllEv; 
	tables ip*ie; 
run;

proc freq data=regal.PatAllEv; 
	tables new_patientstat*alive; 
run;

/*data aa; */
/*	set regal.PatAllEv; */
/*	d1=datlcont-new_datelastcontact;*/
/*	d2=datdeath-new_deathdate;*/
/*run;*/
/**/
/*proc print; */
/*	var d1 d2; */
/*run;*/
/**/
/**/

data tmp;
	set regal.PatAllEv; 
	if center='рег';
run;

proc sort data = tmp;
	by new_diag;
run;

proc means data=tmp N median  min max; 
	by new_diag;
	var new_diagnosisage; 
	format new_diag new_diag_f.;
	title "Только по регионам";
run;

proc freq data=tmp; 
	tables gendercode / nocum;;
	format gendercode gendercode_f. new_diag new_diag_f.; 
run;

proc freq data=tmp;
	by  new_diag;
	tables inPr*alive / nocum;;
	format gendercode gendercode_f. inPr inPr_f.  new_diag new_diag_f. alive yn_f.; 
run;


/*
new_contact Символьная 36 $36. $36. GUID Пациента  
4 new_contact_ol Символьная 36 $36. $36. GUID Острые_Лейкозы  
3 new_contactname Символьная 34 $34. $34. ФИО Пациента  
6 new_event Числовая 8 DDMMYY10. DDMMYY10. ID Тип события  
5 new_event_date Символьная 34 $34. $34. Дата события  
1 new_event_ostrleykid Символьная 36 $36. $36. GUID События  
8 new_event_txt Символьная 45 $45. $45. Комментарий события  
7 new_eventname Числовая 8 BEST12. BEST32. Тип события  




proc freq data=patall; tables 
new_contactname*fullname/list; run;
*/

