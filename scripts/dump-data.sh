

# Dump data
currdate=$(date +%Y%m%d)
rake dump:data
(cd ../trefle-data && git add . && git commit -m "Dump from $currdate")
(cd ../trefle-data && git pull origin master && git push origin master && gh release create $currdate 'species.csv#Trefle data' -t "$currdate" -n "This dump has been generated on $currdate")