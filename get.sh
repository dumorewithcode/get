#!/bin/bash
# get.sh - creates a target specific wordlist for pentesting using wayback
# Author: @a3kSec

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`

SECONDS=0

domain=

current_directory=.
basepath=

usage() { echo -e "${yellow}[!] Usage: \"./get.sh domain.com\"  or  \"./get.sh in_scope.txt\"  or  \"cat in_scope.txt | ./get.sh\"" 1>&2; exit 1; }

required_files_exist() {
    if [[ -e $current_directory/out_of_scope.txt && -e $current_directory/in_scope.txt ]]; then
        true
    else
        false
    fi
}

get_subdomains() {
    echo "${green}[+] Getting subdomains"
    echo $domain | anew $basepath/subdomains.txt > /dev/null
    # amass enum --passive -silent -d $domain | grep -v -f "./out_of_scope.txt" | anew "$filename" > /dev/null
    # subfinder -silent -d $domain | grep -v -f $current_directory/out_of_scope.txt | anew $basepath/temp_subdomains.txt > /dev/null
    assetfinder --subs-only $domain | grep -v -f $current_directory/out_of_scope.txt | anew $basepath/temp_subdomains.txt > /dev/null
    cat $basepath/temp_subdomains.txt | httprobe -c 100 --prefer-https | unfurl -u format "%d" | anew $basepath/subdomains.txt > /dev/null
}

get_wayback_results() {
    echo "${green}[+] Getting wayback results"
    cat $basepath/subdomains.txt | gau | grep -ivE ".jpg|.jpeg|.png|.gif|.css|.woff|.woff2|.ttf|.svg|.eot|.json" | anew $basepath/waybackresults.txt > /dev/null
}

get_jsfiles() {
    echo "${green}[+] Getting js files"
    awk '/.js/ {print}' $basepath/waybackresults.txt | anew $basepath/temp_jsfiles.txt > /dev/null
    echo $domain | httpx -silent -no-color | getJS --complete | grep $domain | anew $basepath/temp_jsfiles.txt > /dev/null
    cat $basepath/temp_jsfiles.txt | httpx -no-color -status-code -silent | awk -F '[][]' '$2>199 && $2<300 {print $1}'| anew $basepath/jsfiles.txt > /dev/null
}

scan_jsfiles() {
    echo "${green}[+] Scanning js files"
    while read -r line; do
        python3 ~/tools/LinkFinder/linkfinder.py -i $line -o cli | anew $basepath/linkfinder.txt > /dev/null
    done < $basepath/jsfiles.txt
}

extract_paths() {
    echo "${green}[+] Extracting paths"
    if [[ -e $basepath/linkfinder.txt ]]; then
        cat $basepath/linkfinder.txt | unfurl paths | anew $basepath/paths.txt > /dev/null
    fi
    if [[ -e $basepath/waybackresults.txt ]]; then
        cat $basepath/waybackresults.txt | unfurl paths | anew $basepath/paths.txt > /dev/null
    fi
}

extract_params() {
    echo "${green}[+] Extracting params"
    if [[ -e $basepath/linkfinder.txt ]]; then
        cat $basepath/linkfinder.txt | unfurl keys | anew $basepath/params.txt > /dev/null
    fi
    if [[ -e $basepath/waybackresults.txt ]]; then
        cat $basepath/waybackresults.txt | unfurl keys | anew $basepath/params.txt > /dev/null
    fi
}

extract_urls() {
    echo "${green}[+] Extracting urls"
    if [[ -e $basepath/linkfinder.txt ]]; then
        cat $basepath/linkfinder.txt | grep -f $current_directory/in_scope.txt | anew $basepath/temp_urls.txt > /dev/null
    fi
    if [[ -e $basepath/waybackresults.txt ]]; then
        cat $basepath/waybackresults.txt | unfurl format %s://%d%p | grep -ivE ".jpg|.jpeg|.png|.gif|.css|.woff|.woff2|.ttf|.svg|.eot|.json" | anew $basepath/temp_urls.txt > /dev/null
    fi
    if [[ -e $basepath/temp_urls.txt ]]; then
        cat $basepath/temp_urls.txt | httpx -no-color -status-code -silent | awk -F '[][]' '$2>199 && $2<300 {print $1}' | anew $basepath/urls.txt > /dev/null
        rm $basepath/temp_urls.txt
    fi
}

generate_target_wordlist() {
    echo "${green}[+] Generating wordlist"
    cat $basepath/paths.txt | awk '{ gsub("/", "\n") } 1' | anew $basepath/temp_wordlist.txt > /dev/null
    cat $basepath/temp_wordlist.txt | awk '! /\./ && ! /,/ && ! /:/ && ! /+/ && ! /%/ && ! /;/ && ! /=/ && !/ /'  | anew $basepath/wordlist.txt > /dev/null
}

run_eyewitness() {
    echo "${green}[+] Running eyewitness"
    ~/tools/EyeWitness/Python/EyeWitness.py --web -f $basepath/subdomains.txt -d $basepath/eyewitness --no-prompt > /dev/null
}

cleanup() {
    rm -rf $basepath/linkfinder.txt $basepath/waybackresults.txt $basepath/temp_wordlist.txt $basepath/temp_jsfiles.txt $basepath/temp_subdomains.txt > /dev/null
}

create_required_files() {
    echo "${red}[-] Some required files where not found. Create them?(y/n)"
    while true; do
        echo -n "> "
        read createfiles
        case $createfiles in
            y)
                touch $current_directory/out_of_scope.txt
                touch $current_directory/in_scope.txt
                echo "${yellow}[!] ./out_of_scope.txt and ./in_scope.txt created"
                break
                ;;
            n)
                echo "${yellow}[!] Need required files to run"
                break
                ;;
            *)
                echo "${yellow}[!] Input either \"y\" or \"n\""
                continue
                ;;
        esac;
    done
}

check_if_binaries_exist() {
    binaries=( anew assetfinder amass subfinder httprobe unfurl gau httpx getJS )
    for bin in "${binaries[@]}"; do
        if ! command -v $bin &> /dev/null; then
            echo "$bin could not be found. Install $bin or add to PATH"
            exit 1
        fi
    done
}

main() {
    check_if_binaries_exist
    if required_files_exist; then
        echo "${green}[+] Getting results for [ $domain ]"
        mkdir -p $current_directory/recon/$domain
        basepath=$current_directory/recon/$domain
        get_subdomains
        duration=$SECONDS
        echo "${yellow}[+] $(($duration / 60)) minutes and $(($duration % 60)) elapsed."
        get_wayback_results
        duration=$SECONDS
        echo "${yellow}[+] $(($duration / 60)) minutes and $(($duration % 60)) elapsed."
        get_jsfiles
        duration=$SECONDS
        echo "${yellow}[+] $(($duration / 60)) minutes and $(($duration % 60)) elapsed."
        # scan_jsfiles
        # echo "${yellow}[+] $(($duration / 60)) minutes and $(($duration % 60)) elapsed."
        extract_paths
        duration=$SECONDS
        echo "${yellow}[+] $(($duration / 60)) minutes and $(($duration % 60)) elapsed."
        extract_params
        duration=$SECONDS
        echo "${yellow}[+] $(($duration / 60)) minutes and $(($duration % 60)) elapsed."
        # extract_urls
        # echo "${yellow}[+] $(($duration / 60)) minutes and $(($duration % 60)) elapsed."
        generate_target_wordlist
        duration=$SECONDS
        echo "${yellow}[+] $(($duration / 60)) minutes and $(($duration % 60)) elapsed."
        # run_eyewitness Need to have eyewitness installed to run ~/tools/EyeWitness/Python/EyeWitness.py
        duration=$SECONDS
        echo "${yellow}[+] $(($duration / 60)) minutes and $(($duration % 60)) elapsed."                                        
        cleanup
        duration=$SECONDS
        echo "${green}[+] Completed wordlists for [ $domain ]"
        echo "${green}[+] Results for [ $domain ] took $(($duration / 60)) minutes and $(($duration % 60)) seconds."
        echo ""
    else
        create_required_files
    fi
}

source ~/.bash_profile
if [[ -p /dev/stdin ]]; then
    while IFS= read -r line; do
        if [[ -n $line ]];  then
            domain=$line
            main
        fi
    done
elif [[ -f $1 ]]; then
    cat $1 | while read -r line; do
        if [[ -n $line ]];  then
            domain=$line
            main
        fi
    done
elif [[ -n $1 ]]; then
    domain=$1
    main
else
    echo "${red}[-] Enter a domain"
    usage
fi

stty sane