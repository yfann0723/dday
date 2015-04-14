#!/usr/bin/perl -w
######################################################
# upload a file with netscape 2.0+ or IE 4.0+
# Muhammad A Muquit
# When: Long time ago
# Changelog:
# James Bee" <JamesBee@home.com> reported that from Windows filename
# such as c:\foo\fille.x saves as c:\foo\file.x, Fixed, Jul-22-1999
# Sep-30-2000, muquit@muquit.com
#   changed the separator in count.db to | from :
#   As in NT : can be a part of a file path, e.g. c:/foo/foo.txt
######################################################
#
# $Revision: 5 $
# $Author: Muquit $
# $Date: 3/28/04 9:38p $

#use strict;
use CGI;
# if you want to restrict upload a file size (in bytes), uncomment the
# next line and change the number

#$CGI::POST_MAX=50000;

$|=1;

my $version="V1.4";

## vvvvvvvvvvvvvvvvvvv MODIFY vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

# the text database  of the user. The text database contains the | 
# separated items, namely  login|encrypted password|upload path
# example: muquit|fhy687kq1hger|/usr/local/web/upload/muquit
# if no path is specified, the file must be located in the cgi-bin directory.

my $g_upload_db="upload.db";
my $ip_addr = "75.51.145.73";

# overwrite the existing file or not. Default is to overwrite
# chanage the value to 0 if you do not want to overwrite an existing file.
my $g_overwrite=1;

# if you want to restrict upload to files with certain extentions, change
# the value of $g_restrict_by_ext=1 and ALSO modify the @g_allowed_ext if you
# want to add other allowable extensions.
my $g_restrict_by_ext=0;
# case insensitive, so file with Jpeg JPEG GIF gif etc will be allowed
my @g_allowed_ext=("jpeg","jpg","gif","png");

## ^^^^^^^^^^^^^^^^^^^ MODIFY ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



#-------------- globals---------- STARTS ------------------
my $query=new CGI;
my $g_debug=0;


my $g_title="File upload";
my $g_upload_path='';

#-------------- globals----------  ENDS  ------------------


print $query->header;

# Java Script for form validation
#
my $JSCRIPT=<<EJS;

var returnVal=true;
var DEBUG=0;

//===========================================================================
// Purpose: check if field is blank or NULL
// Params:
//  field (IN)
//  errorMsg (IN - MODIFIED)
//  fieldTitle (IN)
// Returns:
//  errorMsg - error message
// Globals:
//  sets global variable (returnVal) to FALSE if field is blank or NULL
// Comments:
//  JavaScript code adapted from netscape software registration form.
//  ma_muquit\@fccc.edu, May-09-1997
//===========================================================================

function ValidateAllFields(obj)
{
   returnVal = true;
   errorMsg = "The required field(s):\\n";

   // make sure all the fields have values
   if (isSomeFieldsEmpty(obj) == true) 
   {
     // DISPLAY ERROR MSG
     displayErrorMsg();
     returnVal = false;
   }

   if (returnVal == true)
     document.forms[0].submit();
   else
     return (false);
}

//===========================================================================
function displayErrorMsg()
{
   errorMsg += "\\nhas not been completed.";
   alert(errorMsg);
}

//===========================================================================
function isSomeFieldsEmpty(obj)
{
    var
        returnVal3=false;



// check if login is null
   if (obj.userid.value == "" || obj.userid.value == null)
   {
       errorMsg += " " + "Userid" + "\\n";
       returnVal3=true;
   }

// check if Password is null

   if (obj.password.value == "" || obj.password.value == null)
   {
       errorMsg += " " + "Password" + "\\n";
       returnVal3=true;
   }

   return (returnVal3);
}

EJS
;

# print the HTML HEADER
&printHTMLHeader;

if ($query->path_info eq "/author" or $query->path_info eq "/about")
{
    &printForm;
    &printAuthorInfo;
    return;
}

if ($query->param)
{
    &doWork();
}
else
{
    &printForm();
}

##-----
# printForm() - print the HTML form
##-----
sub printForm
{

    print "<center>\n";
    print "<table border=0 bgcolor=\"#c0c0c0\" cellpadding=5 cellspacing=0>\n";

    print $query->start_multipart_form,"\n";

    #------------- userid
    print "<tr>\n";
    print "<td align=\"right\">\n";
    print "Userid:\n";
    print "</td>\n";
    
    print "<td>\n";
    print $query->textfield(-name=>'userid',
            -size=>20);
    print "</td>\n";
    print "</tr>\n";

    #------------- password
    print "<tr>\n";
    print "<td align=\"right\">\n";
    print "Password:\n";
    print "</td>\n";
    
    print "<td>\n";
    print $query->password_field(-name=>'password',
            -size=>20);
    print "</td>\n";
    print "</tr>\n";

   #------------- Yaw: type (proc_type)
#    print "<tr>\n";
#    print "<td colspan=2 align=\"center\">\n";
#    print $query->radio_group(-name=>'proc_type',
#                        -values=>['fifo','arbitor','pipeline','rdl'],
#                        -default=>['fifo'],
#                        -disabled => ['pipeline'],
#    -labels=>\%labels,
#    -attributes=>\%attributes);



    #------------- submit
    print "<tr>\n";
    print "<td colspan=2 align=\"center\">\n";
    print "<hr noshade size=1>\n";
    print $query->submit(-label=>'Submit',
            -value=>'Submit',
            -onClick=>"return ValidateAllFields(this.form)"),"\n";
    print "</td>\n";
    print "</tr>\n";

    print $query->endform,"\n";

    print "</table>\n";
    print "</center>\n";
}



##------
# printHTMLHeader()
##------
sub printHTMLHeader
{
    print $query->start_html(
            -title=>"$g_title",
            -script=>$JSCRIPT,
            -bgcolor=>"#ffffff",
            -link=>"#ffff00",
            -vlink=>"#00ffff",
            -alink=>"#ffff00",
            -text=>"#000000");
}

##-------
# doWork() - upload file 
##-------
sub doWork
{
    ##################
    my $em='';
    ##################


    # import the paramets into a series of variables in 'q' namespace
    $query->import_names('q');
    #  check if the necessary fields are empty or not
    $em .= "<br>You must specify your Userid!<br>" if !$q::userid;
    $em .= "You must specify your Password!<br>" if !$q::password;
#   $em .= "You must select a file to upload!<br>" if !$q::upload_file;

    &printForm();
    if ($em)
    {
        &printError($em);
        return;
    }

    
    # Yaw: passwd (yfann) is in upload.db
    if (&validateUser() == 0)
    {
        &printError("Will not upload! Could not validate Userid: $q::userid");
        return;
    }
    # Yaw
    #print "$proc_type operation will be processed\n";

    #------------- Yaw: process option
# print fifo, arbitor usage
my $usage_path = "/usr/local/web/upload/yfann/usage";
my $cmd_fifo_link = "./cgi_cmd_fifo.pl";
my $cmd_arb_link = "./cgi_cmd_arb.pl";
my $cmd_bypass_link = "./cgi_cmd_bypass.pl";
my $cmd_word_rotator_link = "./cgi_cmd_word_rotator.pl";
print<<EOF;
</tr>
<td colspan=2 align=\"center\">
  Click <a href="$cmd_fifo_link"><font color="FF00CC">here</font></a> to run fifo process.
</br>
  Click <a href="$cmd_arb_link"><font color="FF00CC">here</font></a> to run arbitor process.</br>
  Click <a href="$cmd_bypass_link"><font color="FF00CC">here</font></a> to run bypass process.</br>
  Click <a href="$cmd_word_rotator_link"><font color="FF00CC">here</font></a> to run word rotator process.</br>
</br>
</td>
</tr>
EOF
;

    # check type

    if ($g_debug == 1)
    {
        my @all=$query->param;
        my $name;
        foreach $name (@all)
        {
            print "$name ->", $query->param($name),"<br>\n";
        }
    }
}

##------
# printError() - print error message
##------
sub printError
{
    my $em=shift;
    print<<EOF;
<center>
    <hr noshade size=1 width="80%">
        <table border=0 bgcolor="#000000" cellpadding=0 cellspacing=0>
        <tr>
            <td>
                <table border=0 width="100%" cellpadding=5 cellspacing=1>
                    <tr">
                        <td bgcolor="#ffefd5" width="100%">
                        
                        <font color="#ff0000"><b>Error -</b></font>
                        $em</td>
                    </tr>
                </table>
            </td>
        </tr>
            
        </table>
</center>
EOF
;
}

##--
# validate login name
# returns 1, if validated successfully
#         0 if  validation fails due to password or non existence of login 
#           name in text database
##--
sub validateUser
{
    my $rc=0;
    my ($u,$p);
    my $userid=$query->param('userid');
    my $plain_pass=$query->param('password');  
    # Yaw
    $proc_type=$query->param('proc_type');  

    # open the text database
    unless(open(PFD,$g_upload_db))
    {
        my $msg=<<EOF;
Could not open user database: $g_upload_db
<br>
Reason: $!
<br>
Make sure that your web server has read permission to read it.
EOF
;
        &printError("$msg");
        return;
    }
    
    # first check if user exist
    $g_upload_path='';
    my $line='';
    while (<PFD>)
    {
        $line=$_;
        chomp($line);
        # get rid of CR
        $line =~ s/\r$//g;
        ($u,$p,$g_upload_path)=split('\|',$line);
        if ($userid eq $u)
        {
            $rc=1;
            last;
        }
    }
    close(PFD);

    # Yaw: crypt information
    # ex. need to encrypt "yfann" before it is filled into upload.db
    # ex. $pass = yfann, and use a $salt = "xx"
    # use crypt.pl -> xxMffOT1/wTKE -> entered to encrypted filed in upload.db 
    if (crypt($plain_pass,$p) ne $p)
    {
        $rc=0;
    }
    
    return ($rc);
}

sub printAuthorInfo
{
my $url="http://www.muquit.com/muquit/";
my $upl_url="http://muquit.com/muquit/software/upload_pl/upload_pl.html";
print<<EOF;
<center>
<hr noshade size=1 width="90%">
<table border=0 bgcolor="#c0c0c0" cellpadding=0 cellspacing=0>
<tr>
    <td>
	<table border=0 width="100%" cellpadding=10 cellspacing=2>
	    <tr align="center">
		<td bgcolor="#000099" width="100%">
		<font color="#ffffff">
		<a href="$upl_url">
		upload.pl</a> $version by 
		<a href="$url">Muhammad A Muquit</A>
		</font>
		</td>
	    </tr>
	</table>
    </td>
</tr>
    
</table>
</center>
EOF
;
}

sub print_debug
{
my $msg=shift;
if ($g_debug)
{
print "<code>(debug) $msg</code><br>\n";
    }
}

sub printFile($)
{
  my $file = $_[0];
  while (<$file>) {
    my $line = $_;
    print "$line<br>";
  }
}

