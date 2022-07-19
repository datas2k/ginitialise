<#PSScriptInfo
.VERSION 0.0.2
.GUID db08dfb5-7fac-40a5-aff7-c3fcb49e144a
.AUTHOR s2k
.COMPANYNAME WRC
.COPYRIGHT MIT
.TAGS 
.LICENSEURI 
.PROJECTURI 
.ICONURI 
.EXTERNALMODULEDEPENDENCIES 
.REQUIREDSCRIPTS 
.EXTERNALSCRIPTDEPENDENCIES 
.RELEASENOTES
#>

<# 
.DESCRIPTION 
 Local and Remote Github project initialization script.
 If execution policy is restricted you can't run this script.
 Check with get-executionPolicy command. Then set it to unrestricted with the next command:
 set-executionpolicy unrestricted
 This script utilises git and gh command line tools.
 Git version control system: https://git-scm.com/download/win
 GitHub CLI: https://cli.github.com
#> 

Param (
  [string]$global:repository
);
$global:scriptPath = split-path -parent $MyInvocation.MyCommand.Definition;

function CheckEnv {
  $tools =  @('git',"Git version control system not found...`n get from https://git-scm.com/download/win"),
            @('gh',"GitHub CLI tool not found...`nget from https://cli.github.com/`nor install with chcolatey package manager: chocolatey install gh");
  [bool]$fail = $false;
  foreach($tool in $tools)
  {
    try
    {
      Invoke-Expression $tool[0] | Out-Null
    }
    catch [System.Management.Automation.CommandNotFoundException]
    {
      Write-Host $tool[1] -ForegroundColor Red;
      [bool]$fail = $true;
    }
  };
  if ($fail) {
    Exit;
  } else {
    $status = & gh auth status 2>&1;
    $auth = $status -split "\.";
    if ($auth[0] -ne "github") {
      $txt =  @("$($auth[0]) !`n", "Red"),
              @("Start login process with GitHub CLI ? ", "Yellow"),
              @("(y\n) ","White");
      Dialog( @($txt,"login") );
    } else {
      $username = $status -split "Logged in to github.com as ";
      $username = $username[2] -split " ";
      $username= $username[0];
      Evaluate($username);
    };
  };
};

function Evaluate ($username){
  $txt =  @( "** GitHub user name: ", "Green"),
          @("$($username)`n", "Yellow"),
          @("** Repository name: ", "Green"),
          @("$($global:repository)`n","Yellow"),
          @("** Local repository will be created in: ", "Green"), 
          @("$(Get-Location)\$($global:repository)`n","Yellow"),
          @("   Is that correct ?","Red"),
          @(" (y\n) ","White");
  Dialog( @($txt, @("make",$username) ) );
};

function MakeRepo($username) {
  if ( Test-Path -Path $global:repository ) {
    "GitHub local repository already exists !";
    Exit;
  } else {
    $currDir = "$(Get-Location)";
    New-Item -Path $currDir -Name $global:repository -ItemType "directory" | Out-Null;
    Set-Location $global:repository | Out-Null;
    $readmeTxt = $global:repository;
    New-Item README.md -Value $readmeTxt | Out-Null;
    New-Item .gitignore | Out-Null;
    git init -b main
    git add .
    git commit -m "initial commit"
    git remote add origin git@github.com:$($username)/$($global:repository).git
    gh repo create $global:repository --public --push --source=.
    
    #git push origin master
  };
};

function Login{
  gh auth Login
  exit;
}


function Dialog($array){
  for ($i = 0; $i -lt $array[0].Count; $i++) {
    Write-Host $array[0][$i][0] -NoNewline -ForegroundColor $array[0][$i][1];
  };
  $eval = Read-Host;
  if ($eval -eq "y") {
    Switch ($array[1]) {
      "login" {Login}
      "make" {MakeRepo($array[1][1])}
    }
  } else {
    Exit;
  };
}



function GetData {
  $data = @{};
  $json = Get-Content "$($global:scriptPath)\user.json" | Out-String | ConvertFrom-Json;
  [bool]$fail = $false;
  foreach($e in $json.PsObject.Properties)
  {
    if ( -Not $e.Value ) {
      Write-Host "Missing $($e.Name) in $($global:scriptPath)\user.json file !" -ForegroundColor Red;
      [bool]$fail = $true;
    };
  };
  if ($fail) {
    Exit;
  } else {
    $data.user = $json.username;
    $data.password = $json.password;
    if (-Not $global:repository) {
      $data.repository = Read-Host -Prompt "** Repository name";
    } else {
      $data.repository = $global:repository;
    };
  };
  return $data;
};


CheckEnv;



