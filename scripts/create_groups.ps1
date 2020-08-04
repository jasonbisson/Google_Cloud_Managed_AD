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

$file = "C:\Windows\temp\groups.csv"
$groups = Import-Csv $file

$domain= Get-ADDomain | Select-Object -ExpandProperty Forest
$DistinguishedName= Get-ADDomain | Select-Object -ExpandProperty DistinguishedName
$path="OU=Groups,OU=Cloud,$DistinguishedName" 


foreach ($item in $groups)
{
    New-ADGroup $item.groups -Path "$path" -GroupCategory Security -GroupScope Global -PassThru -Verbose
}