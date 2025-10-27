from holidays import country_holidays
from holidays.constants import OPTIONAL, PUBLIC
hk_general_holidays = country_holidays("HK", years=2026, language="en_US", categories=(OPTIONAL, PUBLIC))
for dt, name in sorted(hk_general_holidays.items()):
    print(dt, name)