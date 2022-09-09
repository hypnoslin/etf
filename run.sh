#!/bin/sh

today=$(date +%Y-%m-%d)
mkdir -p $today

# Create CSV
cat cathy.html | sed -n "/td/p" | sed -n "s/.*<td.*>\(.*\)<\/td>.*/\1/p" | sed "s/ *//g" | sed -nf match_and_print.sed | awk 'NR%3{printf "%s,",$0;next;}1' | sed "s/%//" | awk '!seen[$0]++' > ./$today/00878.csv

curl -s -k https://www.kgifund.com.tw/Fund/Detail?fundID=J015 | sed -n "/td/p" | sed -n "s/.*<td.*>\(.*\)<\/td>.*/\1/p" | sed "s/ *//g" | sed -nf match_and_print.sed | recode html...utf-8 | awk 'NR%3{printf"%s,",$0;next;}1' |  awk '!seen[$0]++' > ./$today/00915.csv

curl 'https://www.cmoney.tw/etf/ashx/e210.ashx' --data-raw 'action=GetShareholdingDetails&stockId=00713' | jq . | sed -n -Ee "/^ *\"(CommKey|CommName|Weights)/p" | awk 'NR%3{printf"%s",$0;next;}1' | sed "s/ *//g" | sed "s/\"//g" | sed "s/[A-Za-z]\+://g" | sed "s/,$//" | sed -n "/^[0-9]\{4\},/p" > ./$today/00713.csv

cat ./$today/00878.csv > ./$today/merged.csv
cat ./$today/00915.csv >> ./$today/merged.csv
cat ./$today/00713.csv >> ./$today/merged.csv

sort -o ./$today/merged.csv ./$today/merged.csv
awk -F, '{a[$1]++;b[$1]=$2;c[$1]+=$3}END{for(i in a){print i,b[i],c[i],a[i];}}' OFS="," ./$today/merged.csv | sort -r -n -t "," -k 3 -o ./$today/merged.csv

sed -i '/1$/q' ./$today/merged.csv

#awk -F, '{i++;s+=$3;a[i]=$1;b[i]=$2;c[i]=$3;d[i]=$4;e[i]+=$3}END{for(j=1;j<13;j++){print a[j],b[j],c[j],d[i],e[i]/s*100;}}' OFS=","  ./$today/merged.csv > ./$today/tmp.csv; mv ./$today/tmp.csv ./$today/merged.csv
awk -F, '{i++;s+=$3;a[i]=$1;b[i]=$2;c[i]=$3;d[i]=$4;e[i]+=$3}END{for(j=1;j<=NR;j++){print a[j],b[j],c[j],d[j],e[j]/s*100;}}' OFS="," ./$today/merged.csv  > ./$today/tmp.csv; mv ./$today/tmp.csv ./$today/merged.csv
