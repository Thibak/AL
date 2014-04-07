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
%let lastname= .;
%macro what_OC;
%if &sysscpl = W32_7PRO %then 
	%do;
		%let disk = D; *sony;
	%end;
%if &sysscpl = X64_7PRO %then 
	%do;
		%let disk = Z; *������;
	%end;
%mend;


/*������������ ��*/
/*data comp;*/
/*	OC = "&sysscpl";*/
/*run;*/
/**/
/*proc print data = COMP;*/
/*run;*/
%what_OC;

%let LN = AL; * ��� ����������;
Libname &LN "&disk.:\AC\AL\SAS"; * ���������� ������;
%let y = cl;
%let cens = (0);
*20, 27, 99, 132, 258, 264;

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

/*proc print data = &LN..Al_al;*/
/*run;*/
/**/
/*proc print data = &LN..Al_ev;*/
/*run;*/
/**/
/*proc print data = &LN..Al_pt;*/
/*run;*/
