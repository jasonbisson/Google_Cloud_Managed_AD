rem
rem Licensed under the Apache License, Version 2.0 (the "License");
rem you may not use this file except in compliance with the License.
rem You may obtain a copy of the License at
rem
rem      http://www.apache.org/licenses/LICENSE-2.0
rem
rem Unless required by applicable law or agreed to in writing, software
rem distributed under the License is distributed on an "AS IS" BASIS,
rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
rem See the License for the specific language governing permissions and
rem limitations under the License.

set FILE="C:\Windows\temp\users.csv"
bq query --use_legacy_sql=false --max_rows 4000 --format csv "SELECT name,number FROM bigquery-public-data.usa_names.usa_1910_current where year = 1975 AND state = 'NJ' ORDER BY number"  > %FILE%