#!/bin/bash

# Script to run preprocessor on all test cases and compare to "gold" files

DATE1=$(date)

cd ..

PARSER=../scripts/react2xml.pl
if [ ! -f "$PARSER" ]; then
  echo $PARSER
  echo "ERROR: ASCII Input parser does not exist"
  exit 1
fi

CLIST=$(ls *inp)

#===================================
# loop over cases
#===================================

for CASE in $CLIST; do

  CASE=`echo $CASE | sed 's/\.inp$//'`

  echo "============================================="
  echo "  Running CASE = $CASE"
  echo "============================================="

  # parse input 
  rm -f $CASE.xml
  perl $PARSER --init $CASE.inp $CASE.xml
  ls -l $CASE.xml

  if [ ! -f "$CASE.xml" ]; then
    echo "ERROR: XML file was not created"
    exit 1
  fi
  if [ ! -f "GOLD/$CASE.xml.gold" ]; then
    echo "GOLD/$CASE.xml.gold"
    echo "ERROR: GOLD XML does not exist"
    exit 1
  fi

  diff  GOLD/$CASE.xml.gold $CASE.xml

done

DATE2=$(date)

echo "Start  Date $DATE1"
echo "Finish Date $DATE2"
