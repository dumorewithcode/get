#!/usr/bin/env python

import os, os.path, subprocess, shutil, concurrent.futures, click, validators


@click.command()

@click.option('--domain', '-d', required=True, help='domain name')
@click.option('--wordlist', '-w', required=True, help='path to wordlist')
@click.option('--recursive-subs/-rsubs', default=False)
@click.option('--out-of-scope', '-oos', help='path to out of scope list')
@click.option('--output', '-o', help='output file path')

 
def main(domain, wordlist, output, recursive_subs, out_of_scope):
    find_subdomains(domain, recursive_subs)
    resolve_hosts()
    if os.path.isfile(out_of_scope):
        out_of_scope(out_of_scope)
    fuzz_directories(wordlist)


def out_of_scope(out_of_scope):
    if os.path.isfile(out_of_scope):
        if os.path.isfile("resolved.txt"):
            with open(outofscope, "r") as oos_file:
                with open("resolved.txt", "r+") as resolved:
                    for i in oos_file:
                        i = i.strip()
                        for j in resolved:
                            j = j.strip()
                            if i == j:
                                resolved.write(j)
        else:
            click.echo("cant find resolved.txt, rerun tool")
    else:
        click.echo("-oos flag does not contain a valid file")

def read_line_in_domains_list(line):
    line = line.strip()
    path = "domains/"+line
    if os.path.isfile(path):
        subprocess.call(["rm", path])
    subprocess.call(["subfinder", "-d", line, "-o", path])
    subprocess.call("cat "+path+" >> domains/domains2.txt", shell=True)
    
    subprocess.call(["rm", path])


def find_subdomains(domain, recursive_subs):
    if validators.domain(domain):
        click.echo('---> starting subfinder')
        subprocess.call(["subfinder","-d",domain,"-o","subfinder.txt"])
        click.echo('---> starting findomain')
        subprocess.call(["findomain","-t",domain,"-u","findomain.txt"])
        click.echo('---> merging files')
        if os.path.isdir("domains"):
            subprocess.call(["rm", "-r", "domains"])    
        subprocess.call(["mkdir", "domains"]) 
        subprocess.call("sort -u subfinder.txt findomain.txt > domains/domains.txt", shell=True)
        subprocess.call(["touch", "domains/domains2.txt"])
    else:
        click.echo("invalid domain")
    
    
    if recursive_subs:
        if os.path.isfile("domains/domains.txt"):
            with open("domains/domains.txt", "r") as file:
                with concurrent.futures.ThreadPoolExecutor() as executor:
                    results = executor.map(read_line_in_domains_list, file)

                    for result in concurrent.futures.as_completed(results):
                        click.echo(result.result())
            
            subprocess.call("sort -u domains/domains.txt domains/domains2.txt > domains.txt", shell=True)
            subprocess.call(["rm", "domains/domains.txt"])
            subprocess.call(["mv", "domains.txt", "domains/"])
        
        else:
            click.echo("no such file named domains.txt")


def resolve_hosts():
    path = "domains/domains.txt"
    if os.path.isfile(path):
        click.echo('---> httprobe running')
        subprocess.call("cat "+path+" | httprobe -c 60 > resolved.txt", shell=True)
    else:
        click.echo("file not found")


def fuzz_directories(wordlist):
    if os.path.isfile("resolved.txt"):
        click.echo('---> bruteforcing directories')
        if os.path.isfile("directories.txt"):
            subprocess.call(["rm", "directories.txt"])
        else:
            subprocess.call(["touch", "directories.txt"])
            
        with open("resolved.txt", "r") as file:
            for line in file:
                line = line.strip()
                line = line+"/FUZZ"
                subprocess.call(["ffuf", "-w", wordlist, "-u", line, "-o", "directory.txt"])
                subprocess.call("cat directory.txt >> directories.txt", shell=True)
                subprocess.call(["rm", "directory.txt"])


if __name__=="__main__":
    main()