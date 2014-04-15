
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


proc sort data=regal.al_al out=pat1; 
	by new_contact; 
run;

data pat11; 
	set pat1; 
	contactid=new_contact; 
run;

proc sort data=regal.al_pt out=pat2; 
	by contactid; 
run;

data patall; 
	merge pat11 pat2; 
	by contactid; 
	if new_diagnosisage<10 then new_diagnosisage=.;
	if new_lpuname='ФГБУ ГНЦ МЗСЦ РФ' then center='ГНЦ';
		else center='регионы';
run;

proc means data=patall n median min max mean; 
	var new_diagnosisage; 
run;

proc means data=patall n median min max mean; 
	var new_diagnosisage; 
	class center; 
run;


*proc freq data=patall; 
*	tables  (new_patientstatname new_diagname new_diagfabname new_diagmkb new_diagmkbname new_etnosname )*center/nopercent norow;
*run;

*proc print data=regal.al_ev label; 
*	var new_contactname new_event new_eventname new_event_date new_event_txt ; 
*run;


proc sort data=regal.al_ev out=ev1; 
	by new_contact; 
run;

data ev2; 
	set ev1; 
	by new_contact;
	retain datdeath datlcont datrel alive rel;
	if first.new_contact then do;
	 datdeath=.; datlcont=.; datrel=.; alive=1; rel=0;
	end;
	if new_event=5 then do datdeath=new_event_date; alive=0; end; 
	if new_event=6 then do datlcont=new_event_date;  end; 
	if new_event=2 then do datlcont=new_event_date;  end; 
	if new_event=4 then do datrel=new_event_date; rel=1; end; 

	if last.new_contact then do;
			contactid=new_contact;
		 	output;
		end;
	label
		datdeath='дата смерти' 
		datlcont='дата п.контакта' 
		datrel='дата рецидива' 
		alive='жив?' 
		rel='рецидив?'
		;
	/*
	proc freq data=ev2; tables alive rel; run;
	*/
run;

data patalev; 
	merge patall (in=inp) ev2 (in=ine); 
	by  contactid; 
	ip=inp; 
	ie=ine; 
run;

proc freq data=patalev; 
	tables ip*ie; 
run;

proc freq data=patalev; 
	tables new_patientstat*alive; 
run;

data aa; 
	set patalev; 
	d1=datlcont-new_datelastcontact;
	d2=datdeath-new_deathdate;
run;

proc print; 
	var d1 d2; 
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

