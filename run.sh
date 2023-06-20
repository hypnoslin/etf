#!/bin/sh

set -xv

# Please modify the $total in awk command
totoal=1400000
today=$(date +%Y-%m-%d)

# We will create a new folder to store data
mkdir -p $today

# Create CSV
# 00878
# curl -s -k https://www.cathaysite.com.tw/fund-details/ECN?tab=portfolio | sed -n "/td/p" | sed -n "s/.*<td.*>\(.*\)<\/td>.*/\1/p" | sed "s/ *//g" | sed -nf match_and_print.sed | awk 'NR%3{printf "%s,",$0;next;}1' | sed "s/%//" | awk '!seen[$0]++' > ./$today/00878.csv
python 00878.py | sed "s/ /\n/g" | sed "s/%//g" | sed "/^$/d" | awk 'NR%2{printf"%s,",$0;next;}1' > ./$today/00878.csv

name=$(awk -F ',' '{print $1}' ./$today/00878.csv)
curl 'https://stock.wespai.com/p/3752' -H 'authority: stock.wespai.com' --compressed > ./tmp.html
# Get stock number by name
for i in $name
do
    sed -n "/>$i</p" ./tmp.html | sed "s/.*dividend_\([0-9]*\)\.html.*/\1/g" >> ./$today/00878_name.csv
done

rm -f ./tmp.html

paste -d "," ./$today/00878_name.csv ./$today/00878.csv > ./$today/tmp.csv
mv ./$today/tmp.csv ./$today/00878.csv
rm -f ./$today/00878_name.csv

if [ ! -s ./$today/00878.csv ]; then
	# The file is empty.
	echo "https://www.cathaysite.com.tw is not available"
	curl -s 'https://www.moneydj.com/ETF/X/Basic/Basic0007A.xdjhtm?etfid=00878.TW' --data-raw 'action=GetShareholdingDetails&stockId=00878' | jq . | sed -n -Ee "/^ *\"(CommKey|CommName|Weights)/p" | awk 'NR%3{printf"%s",$0;next;}1' | sed "s/ *//g" | sed "s/\"//g" | sed "s/[A-Za-z]\+://g" | sed "s/,$//" | sed -n "/^[0-9]\{4\},/p" > ./$today/00878.csv
fi

# 00915
# python 00915.py | sed "/^$/d" | awk 'NR%4{printf "%s,",$0;next;}1' | awk -F ',' '{print $1,$2,$NF}' | sed "s/ *//g" | sed -n -E "/^[0-9]{,4},/p" > ./$today/00915.csv
python 00915.py | sed "/^$/d" | awk 'NR%4{printf "%s,",$0;next;}1' | awk -F ',' '{printf "%s,%s,%s\n", $1,$2,$NF}' | sed "s/ *//g" | sed -n -E "/^[0-9]{,4},/p" > ./$today/00915.csv

if [ ! -s ./$today/00915.csv ]; then
	# The file is empty.
	echo "https://www.kgifund.com.tw is not available"
	curl -s 'https://www.cmoney.tw/etf/ashx/e210.ashx' --data-raw 'action=GetShareholdingDetails&stockId=00915' | jq . | sed -n -Ee "/^ *\"(CommKey|CommName|Weights)/p" | awk 'NR%3{printf"%s",$0;next;}1' | sed "s/ *//g" | sed "s/\"//g" | sed "s/[A-Za-z]\+://g" | sed "s/,$//" | sed -n "/^[0-9]\{4\},/p" > ./$today/00915.csv
fi

# 00713
python 00713.py | sed -E -n "/^(商品代碼|商品名稱|商品權重)/p" | awk '{print $2}' | awk 'NR%3{printf "%s,",$0;next;}1' > ./$today/00713.csv

# Merge
cat ./$today/00878.csv > ./$today/merged.csv
cat ./$today/00915.csv >> ./$today/merged.csv
cat ./$today/00713.csv >> ./$today/merged.csv

sort -o ./$today/merged.csv ./$today/merged.csv
awk -F, '{a[$1]++;b[$1]=$2;c[$1]+=$3}END{for(i in a){printf "%d,%s,%.2f,%d\n", i,b[i],c[i],a[i];}}' OFS="," ./$today/merged.csv | sort -r -n -t "," -k 3 -o ./$today/merged.csv

# Include before we slice the list
include=$(cat ./include.conf | awk '{print $1;}')

echo "Include,,,,,,," > ./$today/include

if [[ -a exclude ]]; then
    echo "exclude is an array"
    for i in ${include[@]}
    do
        sed -n "/$i/p" ./$today/merged.csv | sed "s/$/,,,,/" >> ./$today/include
        sed -i "/$i/d" ./$today/merged.csv
    done
else
    for i in $include
    do
        sed -n "/$i/p" ./$today/merged.csv | sed "s/$/,,,,/" >> ./$today/include
        sed -i "/$i/d" ./$today/merged.csv
    done
fi


# Find the stock is selected by only one fund, and keep it and slice the rest
# cp ./$today/merged.csv ./$today/rest.csv
sed -i '/1$/q' ./$today/merged.csv

# Exclude
exclude=$(cat ./exclude.conf | awk '{print $1;}')

echo "Exclude,,,,,,," > ./$today/exclude

if [[ -a exclude ]]; then
    for i in ${exclude[@]}
    do
        sed -n "/$i/p" ./$today/merged.csv | sed "s/$/,,,,/" >> ./$today/exclude
        sed -i "/$i/d" ./$today/merged.csv
    done
else
    for i in $exclude
    do
        sed -n "/$i/p" ./$today/merged.csv | sed "s/$/,,,,/" >> ./$today/exclude
        sed -i "/$i/d" ./$today/merged.csv
    done
fi

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

rm -f ./$today/stock_close.csv

awk -F, '{s=1000000*$5/100/$6/1000;printf"%.1f\n", s}' ./$today/merged.csv > ./$today/count.csv 
paste -d "," ./$today/merged.csv ./$today/count.csv > ./$today/tmp.csv
mv ./$today/tmp.csv ./$today/merged.csv
rm -f ./$today/count.csv

awk -F , '{x[xc++]=$7}END{for(i = 0; i < xc; i++) if(i < xc/2 && index(x[i], ".0") == 0) printf "%d\n", x[i]+1 ; else printf "%d\n", x[i];}' ./$today/merged.csv > ./$today/adjust_count.csv
paste -d "," ./$today/merged.csv ./$today/adjust_count.csv > ./$today/tmp.csv
mv ./$today/tmp.csv ./$today/merged.csv
rm -f ./$today/adjust_count.csv

cat ./$today/exclude >> ./$today/merged.csv
rm -f ./$today/exclude

cat ./$today/include >> ./$today/merged.csv
rm -f ./$today/include

# Insert csv header
sed  -i '1i Number,Name,Fund Rate,Count,Rate,Close Price,Amount,Adjust Amount' ./$today/merged.csv
