
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/*****************                                                                       *******************/
/****************                      ����� �� ��������� ��                              ******************/
/*****************                                                                       *******************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/

/*������������� �����*/ *D - sony, Z - ���;
*��� ���������� ����������� �� ��������;
%let disk = .;

%macro what_OC;
%if &sysscpl = W32_7PRO %then 
	%do;
		%let disk = C:\Users\user\Documents\GitHub\AL; *sony;
	%end;
%else/*%if &sysscpl = "W32_7PRO" %then */ 
	%do;
		%let disk = Z:\AC\AL; *���������;
	%end;
%mend;

%what_OC;

Libname regal "&disk.\SAS";* ���������� ������;


%macro Eventan(dat,T,C,i,s,cl,f,for, ttl);
/*
dat -��� ������ ������,
T - �����,
C - ������ �������/��������������,
i=0, ���� � ������ �������,
i=1, ���� � ������ ��������������.
s = �����,���� �������� ������ ������������
s = F, ���� �������� ������ ����������� �����������
cl = cl,���� ���������� ������������� ��������
cl = �����,���� �� ���������� ������������� ��������
s = F, ���� �������� ������ ����������� �����������
f = ������ (������) ���� ����� �� ��� ������
for = ������ (1.0 ��� ������������� ��������, ����� ��� ������������ �������)
ttl = ���������
*/

data _null_; set &dat;
   length tit1 $256 tit2 $256;
*������ ��������;
tit1=vlabel(&T);
%if &f ne %then %do; tit2=vlabel(&f);%end;
   * �������� ������� � ���������������;
   call symput('tt1',tit1);
   call symput('tt2',tit2);
output;
   stop;
   keep tit1 tit2;
run;
title1 &ttl;
title2 " ���������:  &tt1 // ������       :  &tt2";
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
/****************                        ������ ���������                                ******************/
/*****************                                                                       *******************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/


*�������������� �������;
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
    value new_diag_f 1 = "���" 2 = "���" 3 = "���" ; 
	value gendercode_f 1 = "�" 2 = "�";
	value inPr_f 1 = "������� � ��������" 0 = "�� ���. � ��.";
	value yn_f 1 = "��" 0 = "���";
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

*-- �������� ������� ��������� --;

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
	if new_lpuname='���� ��� ���� ��' then center='���';
		else center='���';
run;

*--------------------------------;

*---------- ���������� -----------;
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

	if new_event=1 then do; inPr=1; end; 	*��������� � ����-���� ��������;
	if new_event=2 then do; datlcont=new_event_date;  end; 
	if new_event=4 then do; datrel=new_event_date; rel=1; end; 
	if new_event=5 then do; datdeath=new_event_date; alive=0; end; 
	if new_event=6 then do; datlcont=new_event_date;  end; 


	if last.pt_id then output;

	label
		datdeath='���� ������' 
		datlcont='���� �.��������' 
		datrel='���� ��������' 
		alive='���?' 
		rel='�������?'
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


*---- ���������� ������ ��� ����������� ������� ----;

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

%eventan (regal.PatAllEv, TLive, alive, 1,,cl,,,"����� ������������");
/*%eventan (&LN..new_pt, TLive, i_death, 0,,&y,new_normkariotipname,,"������������� �� ���������. ������������");*/

/*
Eventan(dat,T,C,i,s,cl,f,for, ttl)
dat - ��� ������ ������,
T   - �����,
C   - ������ �������/��������������,
i   - ������������ 
	i = 0, ���� � ������ �������,
	i = 1, ���� � ������ ��������������.
s   - �����,���� �������� ������ ������������
	s = F, ���� �������� ������ ����������� �����������
cl  - �����,���� �� ���������� ������������� ��������
	cl = cl, ���� ���������� ������������� ��������
f   - ������ (������) ���� ����� �� ��� ������
for - ������ (1.0 ��� ������������� ��������, ����� ��� ������������ �������)
ttl - ���������
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
	if center='���';
run;

proc sort data = tmp;
	by new_diag;
run;

proc means data=tmp N median  min max; 
	by new_diag;
	var new_diagnosisage; 
	format new_diag new_diag_f.;
	title "������ �� ��������";
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
new_contact ���������� 36 $36. $36. GUID ��������  
4 new_contact_ol ���������� 36 $36. $36. GUID ������_�������  
3 new_contactname ���������� 34 $34. $34. ��� ��������  
6 new_event �������� 8 DDMMYY10. DDMMYY10. ID ��� �������  
5 new_event_date ���������� 34 $34. $34. ���� �������  
1 new_event_ostrleykid ���������� 36 $36. $36. GUID �������  
8 new_event_txt ���������� 45 $45. $45. ����������� �������  
7 new_eventname �������� 8 BEST12. BEST32. ��� �������  




proc freq data=patall; tables 
new_contactname*fullname/list; run;
*/

