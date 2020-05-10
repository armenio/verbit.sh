#!/bin/bash

# verbit - Utility to parse a Linux Alsa Codec Dump and display the verbs used.
#                    Some basic verb modifications needed for AppleHDA are displayed as well.
#
#                    version 1.0 - This version assists with simple verb decoding and it is
#                                                up to the user to choose which nodes and any final modifications
#                                                to make.
#
# Many Thanks to THe KiNG    
# Signal64                                                

blacklist[0]="411111f0"
blacklist[1]="400000f0"
blacklist[2]="CD at Int ATAPI"

codecfile=$1
debug=$(dirname $1)/verbitdebug.txt

typeset -i i=0
typeset -i j=0
typeset -i verbcount=0
typeset -i nextassoc=0

brk="--------------------------------------------------------------------------------------------------------"

if [[ ! -f $codecfile ]];then
     echo "ERROR: Could not find codec dump file: $codecfile"
     exit
fi

# Simple check to see if this is a ALSA codec dump file
chk=`head -4 $codecfile | sed '/AFG Function Id/d' | cut -f1 -d":" | tr "\n" " " | tr -d " "`

if [[ $chk != "CodecAddressVendorId" ]];then
     echo "ERROR: This doesn't appear to be an alsa codec dump file"
     head -4 $codecfile
     exit
fi

####################################################################
# Start - Parse and display original codec info from file

> $debug
echo -e "\nVerbs from Linux Codec Dump File: $codecfile"

codecname=`head $codecfile | grep Codec: | cut -f2 -d":" | cut -f2- -d" "`
codecaddr=`head $codecfile | grep Address: | cut -f2 -d":"`
codechex=`head $codecfile | grep "Vendor Id:" | cut -f2 -d":"`
codecdec=`printf "%d" $codechex`

printf "\nCodec: %s     Address: %s     DevID: %s (%s)\n" "$codecname" $codecaddr $codecdec $codechex

echo -e "\n     Jack     Color    Description                                    Node         PinDefault                         Original Verbs\n$brk"
 
#addr=`grep Address $codecfile | cut -f2 -d" "`

function debug
{
    echo ""
    echo "$1"
    echo ""
}

typeset -i nidnum=0

while read line;do
 
     chknode=`echo $line | grep "Node 0x" | cut -f2 -d" "`
     if [[ -n $chknode ]];then
            hexnode=$chknode
            vnode=`echo $hexnode | cut -f2 -d"x"` 
     fi

     pin=`echo $line | grep "Pin Default" | cut -f2 -d"x" | cut -f1 -d":"`

     if [[ -n $pin ]];then
        
            EAPD=$(grep -A8 "Node $hexnode" $codecfile | grep "EAPD 0")
            if [ "$EAPD" != "" ]; then
                EAPD=""
            fi

            if [ "$EAPD" != "" ]; then
                desc=`echo $line | cut -f2 -d"]"`
                jack=`grep -A9 "Node $hexnode" $codecfile | grep -A2 "$pin" | grep Color | cut -f2 -d"=" | cut -f1 -d","`
                color=`grep -A9 "Node $hexnode" $codecfile | grep -A2 "$pin" | grep Color | cut -f3 -d"="`
                conntype=`grep -A9 "Node $hexnode" $codecfile | grep -A2 "$pin" | grep '\[*\]' | cut -f2 -d"[" | cut -f1 -d"]"`
            else
                desc=`echo $line | cut -f2 -d"]"`
                jack=`grep -A8 "Node $hexnode" $codecfile | grep -A2 "$pin" | grep Color | cut -f2 -d"=" | cut -f1 -d","`
                color=`grep -A8 "Node $hexnode" $codecfile | grep -A2 "$pin" | grep Color | cut -f3 -d"="`
                conntype=`grep -A8 "Node $hexnode" $codecfile | grep -A2 "$pin" | grep '\[*\]' | cut -f2 -d"[" | cut -f1 -d"]"`
            fi
echo "$desc"
            direction=`grep -A9 "Node $hexnode" $codecfile | grep 'ControlAmp' | grep "dir=" | sed -E 's/^.*dir=([^,]*).*$/\1/'
            # 
            #x | cut -f2 -d"=" | cut -f1 -d","`
            
            # 71c Default Association/Sequence
            verb1=$codecaddr$vnode"71c"`echo $pin | cut -c7,8`

            # 71d Color/Misc 
            verb2=$codecaddr$vnode"71d"`echo $pin | cut -c5,6`
             
            # 71e Default Device/Connection Type
            verb3=$codecaddr$vnode"71e"`echo $pin | cut -c3,4`

            # 71f Port Connectivity/Location
            verb4=$codecaddr$vnode"71f"`echo $pin | cut -c1,2`

            # 70c EAPD
            if [ "$EAPD" != "" ]; then
                eapd=$codecaddr$vnode"70c0"`echo $EAPD | cut -c8`
            else
                eapd=""
            fi

            printf "%7s %7s %-27s %3d %-6s %-12s %s %s %s %s\n" $jack $color "$desc" $hexnode $hexnode "0x"$pin $verb1 $verb2 $verb3 $verb4

            chkblklist="$conntype $jack $color $desc $hexnode 0x$pin $eapd"

            blklisted=0;i=0
            while [ $i -lt ${#blacklist[@]} ];do
                 chk=`echo $chkblklist | grep "${blacklist[i]}"`
                 if [[ $chk ]];then
                        blklisted=1
                 fi
                 i=i+1
            done
                 
            #if [[ $blklisted = 0 ]];then
                 vdesc[verbcount]=`echo "$desc" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
                 vjack[verbcount]=`echo $jack | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
                 vcolor[verbcount]=`echo $color | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
                 vconntype[verbcount]=`echo $conntype | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
                 vdirection[verbcount]=`echo $direction | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
                 vhex[verbcount]=`echo $hexnode | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
                 vpin[verbcount]=`echo $pin | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
                 verbc[verbcount]=`echo $verb1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
                 verbd[verbcount]=`echo $verb2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
                 verbe[verbcount]=`echo $verb3 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
                 verbf[verbcount]=`echo $verb4 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
                 veapd[verbcount]=`echo $eapd | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
                 verbcount=verbcount+1
            #else
                 blnodes=$blnodes$hexnode" "
            #fi

     fi

done < $codecfile

echo -e "$brk\n"

echo ""
echo ""

printf "%3s %3s %-6s %-17s %-8s %-8s %-8s %-8s %-8s          %s\n" "Seq" "D" "Node" "Pin" "Verb C" "Verb D" "Verb E" "Verb F" "EAPD" "Notes"

echo "$brk"

i=0
j=1
while [ $i -lt $verbcount ]; do


    #if [ "${vconntype[i]}" == "N/A" ]; then
        #i=i+1
        #continue
    #fi


    notes=`printf "%-3s\n" "$j"`
    #X = Default Association
    #Values: 1, 2, 3, 4, 5, 6, 7, 8, 9, a, b, c, d and f
    #Y = Sequence 
    #Values: Always set this to '0' because Apple dont use analog multi outputs in their codec.

    assoc=`echo ${verbc[i]} | cut -c7`
    if [[ $assoc = 0 ]]; then
         assoc=1
    fi

    
    #verbc[i]="`echo ${verbc[i]} | cut -c1-6`${assoc}0"
    #verbc[i]="`echo ${verbc[i]} | cut -c1-6`${j}0"
    seq=`printf "%x\n" "$j"`
    verbc[i]="`echo ${verbc[i]} | cut -c1-6`${seq}0"

    notes=`printf "%s %-8s\n" "$notes" "0-Always"`













    notes=`printf "%s -- \n" "$notes"`

    color=`echo ${verbd[i]} | cut -c7`
    
    #shopt -s nocasematch
    case "${vcolor[i]}" in
        "Unknown") color="0";;
        "Black") color="1";;
        "Grey") color="2";;
        "Blue") color="3";;
        "Green") color="4";;
        "Red") color="5";;
        "Orange") color="6";;
        "Yellow") color="7";;
        "Purple") color="8";;
        "Pink") color="9";;
        "Reserved") color="A-D";;
        "White") color="E";;
        "Other") color="F";;
        # *) color=0;;
    esac

    notes=`printf "%s %-10s\n" "$notes" "$color-${vcolor[i]}"`

    # Misc - Jack detect sensing capability
    #  Values:
    #    1 for Internal Devices(Speaker etc.,) and
    #    0 for External Devices(Headphones etc.,)
    misc="0"
    #debug "`echo ${vdesc[i]} | grep -y 'Int'`"
    #debug "${verbd[i]}"
    if [ "`echo ${vdesc[i]} | grep -y ' at Int'`" != "" ]; then
        misc="1"
        notes=`printf "%s %-10s\n" "$notes" "$misc-Internal"`
    else
        notes=`printf "%s %-10s\n" "$notes" "$misc-External"`
    fi

    verbd[i]="`echo ${verbd[i]} | cut -c1-6`${color}${misc}"
    #debug "${verbd[i]}"












    notes=`printf "%s -- \n" "$notes"`

    dtype=`echo ${verbe[i]} | cut -c7`

    if [ "`echo ${vdesc[i]} | grep -y 'Line Out'`" != "" ]; then
        dtype="0"
        notes=`printf "%s %-10s\n" "$notes" "$dtype-Line Out"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'Speaker'`" != "" ]; then
        dtype="1"
        notes=`printf "%s %-10s\n" "$notes" "$dtype-Speaker"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'HP Out'`" != "" ]; then
        dtype="2"
        notes=`printf "%s %-10s\n" "$notes" "$dtype-HP Out"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'CD'`" != "" ]; then
        dtype="3"
        notes=`printf "%s %-10s\n" "$notes" "$dtype-CD"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'SPDIF Out'`" != "" ]; then
        dtype="4"
        notes=`printf "%s %-10s\n" "$notes" "$dtype-SPDIF Out"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'Digital Other Out'`" != "" ]; then
        dtype="5"
        notes=`printf "%s %-10s\n" "$notes" "$dtype-Digital O. Out"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'Modem Line Side'`" != "" ]; then
        dtype="6"
        notes=`printf "%s %-10s\n" "$notes" "$dtype-Modem L. Side"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'Modem Hand\(set Side\)\?'`" != "" ]; then
        dtype="7"
        notes=`printf "%s %-10s\n" "$notes" "$dtype-Modem H."`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'Line In'`" != "" ]; then
        dtype="8"
        notes=`printf "%s %-10s\n" "$notes" "$dtype-Line In"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'AUX'`" != "" ]; then
        dtype="9"
        notes=`printf "%s %-10s\n" "$notes" "$dtype-AUX"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'Mic \(at \)\?Int\?'`" != "" ]; then
        dtype="a"
        notes=`printf "%s %-10s\n" "$notes" "$dtype-Mic In"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'Telephony'`" != "" ]; then
        dtype="b"
        notes=`printf "%s %-10s\n" "$notes" "$dtype-Telephony"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'SPDIF In'`" != "" ]; then
        dtype="c"
        notes=`printf "%s %-10s\n" "$notes" "$dtype-SPDIF In"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'Digital Other In'`" != "" ]; then
        dtype="d"
        notes=`printf "%s %-10s\n" "$notes" "$dtype-Digital O. In"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'Reserved'`" != "" ]; then
        dtype="e"
        notes=`printf "%s %-10s\n" "$notes" "$dtype-Reserved"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'Other'`" != "" ]; then
        dtype="f"
        notes=`printf "%s %-10s\n" "$notes" "$dtype-Other"`
    fi

    ctype=`echo ${verbe[i]} | cut -c8`

    if [ "`echo ${vjack[i]} | grep -y '1/8'`" != "" ]; then
        ctype="1"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-1/8"`
    fi
    if [ "`echo ${vjack[i]} | grep -y '1/4'`" != "" ]; then
        ctype="2"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-1/4"`
    fi
    if [ "`echo ${vjack[i]} | grep -y 'Digital'`" != "" ]; then
        ctype="6"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-Digital"`
    fi
    if [ "`echo ${vjack[i]} | grep -y 'Analog'`" != "" ]; then
        ctype="7"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-Analog"`
    fi



    if [ "`echo ${vjack[i]} | grep -y 'Unknown'`" != "" ]; then
        ctype="0"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-Unknown"`
    fi
    if [ "`echo ${vjack[i]} | grep -y '1/8 \(stereo\|mono\)'`" != "" ]; then
        ctype="1"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-1/8"`
    fi
    if [ "`echo ${vjack[i]} | grep -y '1/4 \(stereo\|mono\)'`" != "" ]; then
        ctype="2"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-1/4"`
    fi
    if [ "`echo ${vjack[i]} | grep -y 'ATAPI internal'`" != "" ]; then
        ctype="3"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-ATAPI int"`
    fi
    if [ "`echo ${vjack[i]} | grep -y 'RCA'`" != "" ]; then
        ctype="4"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-RCA"`
    fi
    if [ "`echo ${vjack[i]} | grep -y 'Optical'`" != "" ]; then
        ctype="5"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-Optical"`
    fi
    if [ "`echo ${vjack[i]} | grep -y 'Other Digital'`" != "" ]; then
        ctype="6"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-O. Digital"`
    fi
    if [ "`echo ${vjack[i]} | grep -y 'Other Analog'`" != "" ]; then
        ctype="7"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-O. Analog"`
    fi
    if [ "`echo ${vjack[i]} | grep -y 'Multichannel Analog (DIN)'`" != "" ]; then
        ctype="8"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-M. A. (DIN)"`
    fi
    if [ "`echo ${vjack[i]} | grep -y 'XLR/Professional'`" != "" ]; then
        ctype="9"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-XLR/Pro."`
    fi
    if [ "`echo ${vjack[i]} | grep -y 'RJ-11 (Modem)'`" != "" ]; then
        ctype="a"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-RJ-11 (Modem)"`
    fi
    if [ "`echo ${vjack[i]} | grep -y 'Combination'`" != "" ]; then
        ctype="b"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-Combination"`
    fi
    if [ "`echo ${vjack[i]} | grep -y 'Other'`" != "" ]; then
        ctype="f"
        notes=`printf "%s %-10s\n" "$notes" "$ctype-Other"`
    fi



    verbe[i]="`echo ${verbe[i]} | cut -c1-6`${dtype}${ctype}"









    notes=`printf "%s -- \n" "$notes"`


    # 11 - Jack and Internal device are attached
    b1=""

    # 01 - No External Port -or- No physical connection for Port**
    if [ "${vconntype[i]}" == "N/A" ]; then
        b1="01"
    fi

    # 00 - Port is connected to a Jack
    if [ "${vconntype[i]}" == "Jack" ]; then
        b1="00"
    fi

    # 10 - Fixed Function/Built In Device (integrated speaker, mic, etc)
    if [ "${vconntype[i]}" == "Fixed" ]; then
        b1="10"
    fi

    notes=`printf "%s %-8s\n" "$notes" "$b1-${vconntype[i]}"`

    # 11 Other
    
    #if [ "`echo ${vdesc[i]} | grep -y 'at Int'`" != "" ]; then
    #    b2="01" # Internal
    #fi
    #if [ "`echo ${vdesc[i]} | grep -y 'at Ext'`" != "" ]; then
    #    b2="00" #External on primary chassis 
    #fi
    #notes=`printf "%s %-6s\n" "$notes" "$b2-${vdirection[i]}"`

    b2="11" 
    if [ "`echo ${vdesc[i]} | grep -y ' at Int'`" != "" ]; then
        b2="01" # Internal
        notes=`printf "%s %-6s\n" "$notes" "$b2-Internal"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y ' at Ext'`" != "" ]; then
        b2="00" #External on primary chassis 
        notes=`printf "%s %-6s\n" "$notes" "$b2-External"`
    fi


    b3=""
    if [ "`echo ${vdesc[i]} | grep -y 'at [^ ]* N/A'`" != "" ]; then
        b3="0000"
        notes=`printf "%s %-12s\n" "$notes" "$b3-N/A"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'at [^ ]* Rear'`" != "" ]; then
        b3="0001"
        notes=`printf "%s %-12s\n" "$notes" "$b3-Rear"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'at [^ ]* Front'`" != "" ]; then
        b3="0010"
        notes=`printf "%s %-12s\n" "$notes" "$b3-Front"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'at [^ ]* Left'`" != "" ]; then
        b3="0011"
        notes=`printf "%s %-12s\n" "$notes" "$b3-Left"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'at [^ ]* Right'`" != "" ]; then
        b3="0100"
        notes=`printf "%s %-12s\n" "$notes" "$b3-Right"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'at [^ ]* Top'`" != "" ]; then
        b3="0101"
        notes=`printf "%s %-12s\n" "$notes" "$b3-Top"`
    fi
    if [ "`echo ${vdesc[i]} | grep -y 'at [^ ]* Bottom'`" != "" ]; then
        b3="0110"
        notes=`printf "%s %-12s\n" "$notes" "$b3-Bottom"`
    fi

    hex=$(printf "%x\n" $((2#${b1}${b2}${b3})))

    if [ ${#hex} == 1 ]; then
        hex="0$hex"
    fi

    notes=`printf "%s Hex: %s Bin: %s%s%s\n" "$notes" "$hex" "$b1" "$b2" "$b3"`

    #debug ""
    #debug "${b1} ${b2} ${b3}"
    #debug "$hex"
    #debug ""

    verbf[i]="`echo ${verbf[i]} | cut -c1-6`${hex}"



    #bits="$b1 $b2 $b3"
    #notes=`printf "%s %s %s %s %s\n" "$notes" $hex $b1 $b2 $b3`

    printf "%3s %3d %-6s 0x%-15s %-8s %-8s %-8s %-8s %-8s          %s\n" "$j" "${vhex[i]}" "${vhex[i]}" "${vpin[i]}" "${verbc[i]}" "${verbd[i]}" "${verbe[i]}" "${verbf[i]}" "${veapd[i]}" "$notes"

    #printf "%7s %7s %-27s %3d %-6s %-12s %s %s %s %s %-8s %s\n" ${vjack[i]} ${vcolor[i]} "${vdesc[i]}" "${vhex[i]}" "${vhex[i]}" "0x"${vpin[i]} ${verbc[i]} ${verbd[i]} ${verbe[i]} ${verbf[i]} "${veapd[i]}" "$notes"

    i=i+1
    j=j+1
done

echo -e "$brk\n"
exit 0
# Show nodes that were blacklisted and removed
echo "Blacklist:" >> $debug
echo ${blacklist[*]} >> $debug
echo "Removed Nodes: $blnodes" >> $debug

# Correct Verbs

# Rules:
# Pin Defaults of 0x411111f0 or 0x400000f0 are removed 
# Remove CD at INT ATAPI
#         Taken Care of by blacklist array above, shouldn't be in current verb array
# 71c Sequence should always be 0
# 71c Association needs to be unique!
# 71d Set all Misc to 0 (Jack Detect Enabled) and determine which should be 1 later 
# 71e - Not Processed in this version 
# 71f Location should not use 02 for Front Panel, use 01 instead 

#
# Step 1 - Correct 71c Associations
#

echo "Checking 71c Associations" >> $debug
echo -e "\nCurrent Associations" >> $debug

i=0
while [ $i -lt $verbcount ]
do
        note=""
        assoc[i]=`echo ${verbc[i]} | cut -c7`
        if [[ ${assoc[i]} = 0 ]];then
             assoc[i]=1
             note=" note: Changed 0 to 1" 
        fi

        # Debug
        echo "${verbc[i]} = ${assoc[i]} $note" >> $debug

        i=i+1
done

# Determine unused association values
i=1;j=0
while (( i < 15 ));do 

     # convert to single hex digit 
     ihex=`printf "%x\n" $i`
     chk=`echo ${assoc[*]} | grep -w $ihex`

            if [[ -z $chk ]];then 
                 unused[j]=$ihex
                 j=j+1
            fi

     i=i+1

done

# Debug
echo -e "\n    Used associations = "${assoc[*]} >> $debug
echo "Unused associations = "${unused[*]} >> $debug
echo -e "\nCorrecting duplicate associations\n" >> $debug

i=0;nextassoc=0
while [ $i -lt $verbcount ]
do
        #build a assoc list without current node being checked 
        j=0;assoclist=""
        while [ $j -lt $verbcount ]
        do
                if [[ $j != $i ]];then
                     assoclist=$assoclist${assoc[j]}" "
                fi
                j=j+1
        done

        echo "Checking if ${assoc[i]} already exists in: $assoclist" >> $debug

        chkassoc=`echo $assoclist | grep -w ${assoc[i]}`

        if [[ -n $chkassoc ]];then

             #There is a duplicate
             #Is this the first time we've seen this association?
             
             echo "     duplicate found - Is this the first time we've seen this association?" >> $debug
             firstassoc=`echo $newassoclist | grep -w ${assoc[i]}`

             if [[ -n $firstassoc ]];then 
                    echo "     no - replacing association with: ${unused[nextassoc]}" >> $debug

                    assoc[i]=${unused[nextassoc]} 
                    nverbc[i]=`echo ${verbc[i]} | cut -c1-6`${assoc[i]}"0"
                    nextassoc=nextassoc+1 

             else
                    echo "     yes - ignoring" >> $debug

                    nverbc[i]=`echo ${verbc[i]} | cut -c1-7`"0"

             fi

        else

             echo "     no duplicate found" >> $debug

             nverbc[i]=`echo ${verbc[i]} | cut -c1-7`"0"

        fi 

        newassoclist=$newassoclist${assoc[i]}" "
        i=i+1
        
done

echo -e "\nNew 71c Associations" >> $debug
echo " Before            After" >> $debug
echo "--------------------------------------------------" >> $debug

i=0
while [ $i -lt $verbcount ]
do
        echo ${verbc[i]}"     "${nverbc[i]}" "${verbd[i]}" "${verbe[i]}" "${verbf[i]} >> $debug
        i=i+1
done

#
# Step 2 - Correcting 71d Misc
#

echo -e "\nReset 71d Misc to 0" >> $debug

i=0
while [ $i -lt $verbcount ]
do
     nverbd[i]=`echo ${verbd[i]} | cut -c1-7`"0"
     #verbd[i]=$verb$b
     i=i+1
done
     

echo -e "New 71d Associations" >> $debug
echo " Before                                After" >> $debug
echo "--------------------------------------------------" >> $debug
i=0
while [ $i -lt $verbcount ]
do
        echo ${verbd[i]}"     "${nverbc[i]}"    "${nverbd[i]}" "${verbe[i]}" "${verbf[i]} >> $debug
        i=i+1
done

#
# Step 3 - Correct 71e 
#

# Removed for now 
 
# 
# Step 4 - Correct 71f
#

echo -e "\nCorrect 71f 02 FP to 01" >> $debug

i=0
while [ $i -lt $verbcount ]
do
     verb=`echo ${verbf[i]} | cut -c1-7`
     misc=`echo ${verbf[i]} | cut -c8 | tr [a-z] [A-Z]`

     if [[ $misc = "2" ]];then
            misc="1"
     fi

     if [[ $misc != "1" ]];then
            misc="0"
     fi

     nverbf[i]=$verb$misc

     i=i+1

done

echo -e "New 71f Associations" >> $debug
echo " Before                                                                        After" >> $debug
echo "--------------------------------------------------" >> $debug
i=0
while [ $i -lt $verbcount ]
do
        echo ${verbd[i]}"     "${nverbc[i]}"    "${nverbd[i]}" "${verbe[i]}"    "${nverbf[i]} >> $debug
        i=i+1
done
echo " " >> $debug


#
# Step 5 - Show new verbs
#

echo -e "\n     Jack     Color    Description                                    Node         PinDefault                         Modified Verbs\n$brk"
i=0
while [ $i -lt $verbcount ]
do
        printf "%7s %7s %-27s %3d %-6s %-12s %s %s %s %s\n" ${vjack[i]} ${vcolor[i]} "${vdesc[i]}" ${vhex[i]} ${vhex[i]} "0x"${vpin[i]} ${nverbc[i]} ${nverbd[i]} ${verbe[i]} ${nverbf[i]}
        i=i+1
done

echo -e "$brk\n"

# verbs in one line

printf "Modified Verbs in One Line:"
i=0
while [ $i -lt $verbcount ]
do
        printf " %s %s %s %s" ${nverbc[i]} ${nverbd[i]} ${verbe[i]} ${nverbf[i]}
        i=i+1
done

echo -e "\n$brk\n"

