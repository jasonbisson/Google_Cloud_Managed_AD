#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

$file = "C:\Windows\temp\users.csv"
$ADUsers = Import-Csv $file 

$domain= Get-ADDomain | Select-Object -ExpandProperty Forest
$DistinguishedName= Get-ADDomain | Select-Object -ExpandProperty DistinguishedName
$path="OU=Users,OU=Cloud,$DistinguishedName"

foreach ($item in $ADUsers)
{ 
        $suffix=(Get-Random -Minimum 0 -Maximum 99999 ). ToString('00000')
        $Username = $item.name
        $Username = $Username.SubString(0,2)
        $Username += $suffix
        $Username = $Username.ToLower() 
        $Firstname = $item.name
        $Lastname  = $item.name
   

       #Check if the user account already exists in AD
       if (Get-ADUser -F {SamAccountName -eq $Username})
       {
               #If user does exist, output a warning message
               Write-Warning "A user account $Username has already exist in Active Directory."
       }
       else
       {
       function Get-RandomCharacters($length, $characters) {
       $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
       $private:ofs=""
       return [String]$characters[$random]
       }
 
       function Scramble-String([string]$inputString){     
       $characterArray = $inputString.ToCharArray()   
       $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
       $outputString = -join $scrambledStringArray
       return $outputString 
       }
 
       $password = Get-RandomCharacters -length 5 -characters 'abcdefghiklmnoprstuvwxyz'
       $password += Get-RandomCharacters -length 1 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
       $password += Get-RandomCharacters -length 1 -characters '1234567890'
       $password += Get-RandomCharacters -length 1 -characters '!"§$%&/()=?}][{@#*+'
       $password = Scramble-String $password
       #If a user does not exist then create a new user account
          
        #Account will be created in the OU listed in the $OU variable in the CSV file; don’t forget to change the domain name in the"-UserPrincipalName" variable
       New-ADUser `
            -SamAccountName $Username `
            -UserPrincipalName "$Username@$domain" `
            -Name "$Username" `
            -GivenName $Firstname `
            -Surname $Lastname `
            -Enabled $True `
            -ChangePasswordAtLogon $True `
            -DisplayName "$Lastname, $Firstname" `
            -Path $path `
            -AccountPassword (convertto-securestring $password -AsPlainText -Force)

       }
}