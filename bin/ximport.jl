#!/usr/bin/env julia

using LedgerTools.Ximport
using Levenshtein

function buildguessmodel(transactions)
    r=Transaction[]
    for t in transactions
        if length(t.text)>0
            push!(r,t)
        end
    end
    return r
end

function guess(model,t)
    if length(model)==0
        return
    end
    bestm=model[1]
    best=1000000
    for m in model
        c=levenshtein(m.matchinfo,t.matchinfo)
        if c<best
            best=c
            bestm=m
        end
    end
    for x in bestm.text
        push!(t.text,";"*x)
    end
    if length(t.text)>1
        if t.text[1][2] in "0123456789"
            while (length(t.text[1])>0)&&(t.text[1][1]!=' ')
                t.text[1]=t.text[1][2:end]
            end
            t.text[1]=";"*t.date*t.text[1]
            spacecount=0
            while spacecount<2
                if length(t.text[2])==0
                    break
                end
                if t.text[2][end]==' '
                    spacecount=spacecount+1
                else
                    spacecount=0
                end
                t.text[2]=t.text[2][1:end-1]
            end
            t.text[2]=t.text[2]*"  "*t.amount
        end
    end
end


function filterpipe(x::String)
    r=Char[]
    for c in x
        if c!='|'
            push!(r,c)
        end
    end
    return String(r)
end

function importasb(newtransactions,fname)
    re=r"(\d\d\d\d/\d\d/\d\d),(\d*),(.*),([+|-]?[\d\.]+)"
    for x in open(readlines,fname)
        m=match(re,strip(x))
        if m!=nothing
            amount=m.captures[4]
            if amount[1]=='-'
                amount=amount[2:end]
            else
                amount="-"*amount
            end
            t=Transaction(m.captures[2],
                          m.captures[1],
                          "\$"*amount,
                          filterpipe(m.captures[3]*"-"*m.captures[4]),
                          String[])
            push!(newtransactions,t)
        end
    end
end

function importofx(newtransactions,fname)
    s=read(fname,String)
    while true
        i=first(something(findfirst("<STMTTRN>", s), 0:-1))
        if i==0
            break
        end
        s=s[i+9:end]
        i=first(something(findfirst("</STMTTRN>", s), 0:-1))
        s1=s[1:i-1]
        s=s[i:end]
        d=Dict{String,String}()
        for s2 in split(s1,'<')
            s3=map(strip,split(s2,'>'))
            if length(s3)==2
                d[s3[1]]=s3[2]
            end
        end
        amount=d["TRNAMT"]
        if amount[1]=='-'
            amount=amount[2:end]
        else
            amount="-"*amount
        end
        date=d["DTPOSTED"]
        date=date[1:4]*"/"*date[5:6]*"/"*date[7:8]
        t=Transaction(d["FITID"],
                      date,
                      "\$"*amount,
                      filterpipe(join([d[k] for k in sort(collect(keys(d)))],'-')),
                      String[])
        push!(newtransactions,t)
    end
end


ledgerfile=nothing
newtransactions=Transaction[]

while length(ARGS)>0
    x=popfirst!(ARGS)
    if x[1]=='-'
        if x=="-asb"
            importasb(newtransactions,popfirst!(ARGS))
        elseif x=="-ofx"
            importofx(newtransactions,popfirst!(ARGS))
        else
            error("Unknown option: ",x)
        end
    else
        if ledgerfile==nothing
            global ledgerfile=x
        else
            error("Can't operate on more than one ledger file.")
        end
    end
end

sort!(newtransactions,by=t->t.date)

ledgercontents,transactions=parseledgerfile(ledgerfile)

for t in newtransactions
    if !haskey(transactions,t.id)
        push!(ledgercontents,t)
        transactions[t.id]=t
    end
end

model=buildguessmodel(values(transactions))

for t in values(transactions)
    if length(t.text)==0
        guess(model,t)
    end
end

writeledgerfile(ledgerfile,ledgercontents)

