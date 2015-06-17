package form;
BEGIN { use myVacuum; }
END {}
return 1;

sub head
{
  my ($img) = @_;
print <<EOHEAD;
<table bgcolor="#3f3f3f" cellpadding="2" cellspacing="0" border="0" width="520"><tr><td>
<table bgcolor="#ffffff" cellpadding="0" cellspacing="0" border="0" width="100%">
<tr><td><img src="images/forms/$img.jpg"></td><td colspan="2">&nbsp;</td></tr>
<tr><td colspan="3">
<center>
EOHEAD
}

sub foot
{
  foot_rs();
}

sub foot_rs
{
print <<EOFOOT;
</center>
</td></tr>
<tr><td colspan="2">&nbsp;</td><td align="right"><input type="image" src="images/forms/reset_submit.jpg" border="0" name="op"></td></tr>
</table>
</td></tr></table>
EOFOOT
}

sub foot2
{
  foot_rp();
}

sub foot_rp
{
print <<EOFOOT;
</center>
</td></tr>
<tr><td colspan="2">&nbsp;</td><td align="right"><input type="image" src="images/forms/reset_preview.jpg" border="0" name="op"></td></tr>
</table>
</td></tr></table>
EOFOOT
}

sub foot_yn
{
  my ($yes, $no) = @_;
print <<EOFOOT;
</center>
</td></tr>
<tr><td colspan="2">&nbsp;</td><td align="right"><a href="$no"><img src="images/forms/no.jpg" border="0"></a><a href="$yes"><img src="images/forms/yes.jpg" border="0"></a></td></tr>
</table>
</td></tr></table>
EOFOOT
}


