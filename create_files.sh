rm 00[0-2][0-9].txt 2>/dev/null
c=0;
n=$(date +%s);
while [[ $((c++)) -lt 20 ]];
do
    echo -n "$c "
    ls -la | \
    gawk '
        BEGIN {
            srand('$((n+$((c*3))))');
        }
        {
            r=rand();
            n=0;
            if(r<0.5 && r>=0.1){
                n=sprintf("%i", r*10)
            }
            printf "%s%"n"s\n",$0,""
        }
    ' > $(printf '%04d' $c).txt;
done
echo "Done!"
