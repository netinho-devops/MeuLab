cat_style()
{
cat <<EOF
<style><!--
/* Font Definitions */
@font-face
	{font-family:Calibri;
	panose-1:2 15 5 2 2 2 4 3 2 4;}
@font-face
	{font-family:Tahoma;
	panose-1:2 11 6 4 3 5 4 4 2 4;}
/* Style Definitions */
p.MsoNormal, li.MsoNormal, div.MsoNormal
	{margin:0in;
	margin-bottom:.0001pt;
	font-size:11.0pt;
	font-family:"Calibri","sans-serif";}
a:link, span.MsoHyperlink
	{mso-style-priority:99;
	color:blue;
	text-decoration:underline;}
a:visited, span.MsoHyperlinkFollowed
	{mso-style-priority:99;
	color:purple;
	text-decoration:underline;}
span.EmailStyle17
	{mso-style-type:personal;
	font-family:"Calibri","sans-serif";
	color:windowtext;}
span.EmailStyle18
	{mso-style-type:personal-reply;
	font-family:"Calibri","sans-serif";
	color:#1F497D;}
.MsoChpDefault
	{mso-style-type:export-only;
	font-size:10.0pt;}
@page WordSection1
	{size:8.5in 11.0in;
	margin:1.0in 1.0in 1.0in 1.0in;}
div.WordSection1
	{page:WordSection1;}
--></style>
EOF
}
cat_table()
{
cat <<EOF
<table class=MsoTableLightListAccent2 border=1 cellspacing=0 cellpadding=0 style='border-collapse:collapse;border:none'>
	<tr><td width=149 valign=top style='width:112.1pt;border:solid #C0504D 1.0pt;border-bottom:none;background:#C0504D;padding:0in 5.4pt 0in 5.4pt'><p class=MsoNormal align=center style='text-align:center'><span style='color:white'>Accounts<b><o:p></o:p></b></span></p></td></tr>
EOF

while read env
do
cat <<EOF
<tr><td width=149 valign=top style='width:112.1pt;border:solid #C0504D 1.0pt;padding:0in 5.4pt 0in 5.4pt'><p class=MsoNormal align=center style='text-align:center'><b>
EOF

printf "$env"

cat <<EOF
<o:p></o:p></b></p></td></tr>
EOF
done<lists.txt

cat <<EOF
</table>
EOF
}
send_mail()
{
/usr/lib/sendmail -t <<EOF
From: BSSPackInfraInt@int.amdocs.com
To: BSSPackInfraInt@int.amdocs.com
Subject: PASSWORD-LESS SSH CONNECTION
Content-Type: text/html; charset="us-ascii"
<html xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-microsoft-com:office:word" xmlns:m="http://schemas.microsoft.com/office/2004/12/omml" xmlns="http://www.w3.org/TR/REC-html40">
<head>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=us-ascii"><meta name=Generator content="Microsoft Word 14 (filtered medium)">
`cat_style`
<!--[if gte mso 9]><xml>
<o:shapedefaults v:ext="edit" spidmax="1026" />
</xml><![endif]--><!--[if gte mso 9]><xml>
<o:shapelayout v:ext="edit">
<o:idmap v:ext="edit" data="1" />
</o:shapelayout></xml><![endif]-->
</head>
<body lang=EN-US link=blue vlink=purple>
	<div class=WordSection1>
	<p class=MsoNormal><b><u><span style='color:#C00000'>PASSWORD-LESS SSH CONNECTION<o:p></o:p></span></u></b></p>
	<p class=MsoNormal><b><span style='color:#C00000'><o:p>&nbsp;</o:p></span></b></p>
	<p class=MsoNormal>No password-less ssh connection between <span style='color:#C00000'>${LOGNAME}</span> and below accounts:<o:p></o:p></p>
	<p class=MsoNormal><o:p>&nbsp;</o:p></p>
`cat_table`
</body>
</html>
EOF
}

cd /bssxpinas/bss/tooladm/Scripts/TEST_SSH_CONNECTION
check_ssh_connection.ksh
send_mail
cd -
