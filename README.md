# autocad-use-count
Powershell script that will output how many times a user used AutoCAD each month (with year)  

This script helps the company to decide how many AutoCAD licenses it needs based on how many times the workers use the software and if it's worth to buy (amount)

> Coding languague: English | EN  
> User displayed language: Portuguese | PT

### To run this script you will need a .log file with the TIMESTAMPs (AutoCAD)
The script will then look for file named "autocad.log" located in the same folder as the script and after executing, the output will be saved in a CSV file named "outfile.csv" also located in the same folder as the script.

This filters the .log removing double and empty TIMESTAMPs leaving only the important ones, then saves two lists, one the filtered and the other with unique words (names, dates, timestamps) so to make comparisons for counting uses and then saving it in an array with name, uses, month. It also then converts the date from american to european.  

The last loop will ready up the output to be easy to read.
