param([string]$Dir)
Add-Type -TypeDefinition @"
using System;using System.IO;
public static class Psnr{
 static byte[] Px(string f,out int n){var b=File.ReadAllBytes(f);int nl=0,i=0;while(nl<4){if(b[i]==10)nl++;i++;}n=b.Length-i;var r=new byte[n];Array.Copy(b,i,r,0,n);return r;}
 public static double Mse(string a,string b){int na,nb;var x=Px(a,out na);var y=Px(b,out nb);if(na!=nb)throw new Exception("size");double s=0;for(int i=0;i<na;i++){double d=x[i]-y[i];s+=d*d;}return s/na;}
}
"@
# header: P6, comment, dims, 255 -> 4 lines
$res=@()
foreach($case in '900-static','900-motion','1080-static','1080-motion','720-motion','900-history','1080-history'){
 $a="$Dir\$case-False";$b="$Dir\$case-True";if(!(Test-Path $b)){continue}
 $ms=@();foreach($i in 0..11){$ms+=[Psnr]::Mse("$a\rgb-frame-$i.ppm","$b\rgb-frame-$i.ppm")}
 $m=($ms|Measure-Object -Average).Average;$mx=($ms|Measure-Object -Maximum).Maximum
 $p={param($v) if($v -eq 0){999}else{10*[math]::Log10(255*255/$v)}}
 "{0} psnr_all {1:N2} worst_frame {2:N2}" -f $case,(& $p $m),(& $p $mx)}
