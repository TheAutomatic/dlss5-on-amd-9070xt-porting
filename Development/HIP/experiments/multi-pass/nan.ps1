# nan.ps1 <dir>: count non-finite halves in every rgb-frame-*.f16 / rgb.f16 under <dir> (multi-pass output check).
param([string]$Dir)
Add-Type -TypeDefinition @"
using System;using System.IO;
public static class Nf{public static long Count(string f){var b=File.ReadAllBytes(f);long n=0;for(int i=0;i+1<b.Length;i+=2){int h=b[i]|(b[i+1]<<8);if((h&0x7C00)==0x7C00)n++;}return n;}}
"@
$t=0;$c=0;Get-ChildItem $Dir -Recurse -Filter *.f16|%{$t+=[Nf]::Count($_.FullName);$c++};"NONFINITE files=$c halves=$t"
