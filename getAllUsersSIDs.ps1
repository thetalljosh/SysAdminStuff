gwmi win32_userprofile |

select @{LABEL=”last used”;EXPRESSION={$_.ConvertToDateTime($_.lastusetime)}},

LocalPath, SID | ft -a