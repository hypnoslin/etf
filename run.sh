#!/bin/sh

#set -xv

# Please modify the $total in awk command
totoal=800000
today=$(date +%Y-%m-%d)

# We will create a new folder to store data
mkdir -p $today

# Create CSV
# 00878
curl -s -k https://www.cathaysite.com.tw/funds/etf/fundshares.aspx?fc=CN | sed -n "/td/p" | sed -n "s/.*<td.*>\(.*\)<\/td>.*/\1/p" | sed "s/ *//g" | sed -nf match_and_print.sed | awk 'NR%3{printf "%s,",$0;next;}1' | sed "s/%//" | awk '!seen[$0]++' > ./$today/00878.csv

if [ ! -s ./$today/00878.csv ]; then
	# The file is empty.
	echo "https://www.cathaysite.com.tw is not available"
	curl -s 'https://www.cmoney.tw/etf/ashx/e210.ashx' --data-raw 'action=GetShareholdingDetails&stockId=00878' | jq . | sed -n -Ee "/^ *\"(CommKey|CommName|Weights)/p" | awk 'NR%3{printf"%s",$0;next;}1' | sed "s/ *//g" | sed "s/\"//g" | sed "s/[A-Za-z]\+://g" | sed "s/,$//" | sed -n "/^[0-9]\{4\},/p" > ./$today/00878.csv
fi

# 00915
curl -s -k https://www.kgifund.com.tw/Fund/Detail?fundID=J015 | sed -n "/td/p" | sed -n "s/.*<td.*>\(.*\)<\/td>.*/\1/p" | sed "s/ *//g" | sed -nf match_and_print.sed | recode html...utf-8 | awk 'NR%3{printf"%s,",$0;next;}1' |  awk '!seen[$0]++' > ./$today/00915.csv

if [ ! -s ./$today/00915.csv ]; then
	# The file is empty.
	echo "https://www.kgifund.com.tw is not available"
	curl -s 'https://www.cmoney.tw/etf/ashx/e210.ashx' --data-raw 'action=GetShareholdingDetails&stockId=00915' | jq . | sed -n -Ee "/^ *\"(CommKey|CommName|Weights)/p" | awk 'NR%3{printf"%s",$0;next;}1' | sed "s/ *//g" | sed "s/\"//g" | sed "s/[A-Za-z]\+://g" | sed "s/,$//" | sed -n "/^[0-9]\{4\},/p" > ./$today/00915.csv
fi

# 00713
curl -s 'https://www.cmoney.tw/etf/ashx/e210.ashx' --data-raw 'action=GetShareholdingDetails&stockId=00713' | jq . | sed -n -Ee "/^ *\"(CommKey|CommName|Weights)/p" | awk 'NR%3{printf"%s",$0;next;}1' | sed "s/ *//g" | sed "s/\"//g" | sed "s/[A-Za-z]\+://g" | sed "s/,$//" | sed -n "/^[0-9]\{4\},/p" > ./$today/00713.csv

# Merge
cat ./$today/00878.csv > ./$today/merged.csv
cat ./$today/00915.csv >> ./$today/merged.csv
cat ./$today/00713.csv >> ./$today/merged.csv

sort -o ./$today/merged.csv ./$today/merged.csv
awk -F, '{a[$1]++;b[$1]=$2;c[$1]+=$3}END{for(i in a){print i,b[i],c[i],a[i];}}' OFS="," ./$today/merged.csv | sort -r -n -t "," -k 3 -o ./$today/merged.csv

# Find the stock is selected by only one fund, and keep it and slice the rest
sed -i '/1$/q' ./$today/merged.csv

# Calculate the ratio
awk -F, '{i++;s+=$3;a[i]=$1;b[i]=$2;c[i]=$3;d[i]=$4;e[i]+=$3}END{for(j=1;j<=NR;j++){ printf"%d,%s,%.2f,%d,%.2f\n", a[j],b[j],c[j],d[j],e[j]/s*100}}' OFS="," ./$today/merged.csv  > ./$today/tmp.csv; mv ./$today/tmp.csv ./$today/merged.csv

#cat ./$today/merged.csv

stock_num=$(cat ./$today/merged.csv | awk -F, '{print $1}')

rm -f ./$today/stock_close.csv

# Get latest close price of the stock
for i in $stock_num
do
	echo $(curl -s "https://www.cmoney.tw/notice/chart/stock-chart-service.ashx?action=r&id=$i&date=&ck=ML7EuNTM4B87LWAfCN94XIUVRMUVIHmjrEY%5EDHVQHBWwCRQrCXC3jMk%245OErz&type=&_=1662786737542" -H "Referer: https://www.cmoney.tw/notice/chart/stockchart.aspx?action=r&id=$i&view=1" | jq .RealInfo.SalePrice) >> ./$today/stock_close.csv
done

paste -d "," ./$today/merged.csv ./$today/stock_close.csv > ./$today/tmp.csv
mv ./$today/tmp.csv ./$today/merged.csv

awk -F, '{s=800000*$5/100/$6/1000;printf"%.1f\n", s}' ./$today/merged.csv > ./$today/count.csv 
paste -d "," ./$today/merged.csv ./$today/count.csv > ./$today/tmp.csv
mv ./$today/tmp.csv ./$today/merged.csv

# Insert csv header
sed  -i '1i Number,Name,Fund Rate,Count,Rate,Close Price,Amount' ./$today/merged.csv

