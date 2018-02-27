#!/usr/bin/env julia

using LedgerTools.Ximport

srcledger=ARGS[1]
dstledger=ARGS[2]
match=ARGS[3]
fromacct=ARGS[4]
toacct=ARGS[5]

srccontents,srctransactions=parseledgerfile(srcledger)
dstcontents,dsttransactions=parseledgerfile(dstledger)

newtransactions=Transaction[]

for t in values(srctransactions)
    if (length(t.text)>0)&&(length(t.text[1])>0)&&(t.text[1][1]=='#')
        if strip(t.text[1][2:end])==match
            if !haskey(dsttransactions,t.id)
                t.text=["$(t.date) * $(match)",
                        "    $(fromacct)",
                        "    $(toacct)    $(t.amount)",
                        ""]
                push!(newtransactions,t)
                dsttransactions[t.id]=t
            end
        end
    end
end

sort!(newtransactions,by=t->t.date)

for t in newtransactions
    push!(dstcontents,t)
end

writeledgerfile(dstledger,dstcontents)
