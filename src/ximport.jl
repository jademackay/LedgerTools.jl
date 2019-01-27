module Ximport

export Transaction,tostring,parseledgerfile,writeledgerfile

struct Transaction
    id::String
    date::String
    amount::String
    matchinfo::String
    text::Array{String,1}
end

function tostring(t::Transaction)
    r="|$(t.id)|$(t.date)|$(t.amount)|$(t.matchinfo)\n"
    for x in t.text
        r=r*x*"\n"
    end
    return r
end

function tostring(s::Union{String,SubString{String}})
    return s*"\n"
end


function parseledgerfile(fname)
    ledgercontents=[]
    transactions=Dict{String,Transaction}()
    ls=map(rstrip,open(readlines,fname))

    function noneleft()
        while length(ls)>0
            if (length(ls[1])>0)&&(ls[1][1]==';')
                popfirst!(ls)
            else
                return false
            end
        end
        return true
    end
    
    @label START
    if noneleft()
        @goto DONE
    end
    l=popfirst!(ls)
    if length(l)>0
        if l[1]==';'
            l=l[2:end]
            @goto START
        end
        if l[1]=='|'
            @goto TRANSACTION
        end
    end
    push!(ledgercontents,l)
    @goto START
    
    @label TRANSACTION
    _,id,date,amount,matchinfo=split(l,'|')
    text=String[]

    @label TRANSACTIONTEXT
    if noneleft()
        @goto TRANSACTIONDONE
    end
    if length(ls[1])>0
        if ls[1][1] in "0123456789"
            push!(text,popfirst!(ls))
            @goto TRANSACTIONTEXT2
        end
        if ls[1][1] in "|"
            @goto TRANSACTIONDONE
        end
    end
    push!(text,popfirst!(ls))
    @goto TRANSACTIONTEXT

    @label TRANSACTIONTEXT2
    if noneleft()
        @goto TRANSACTIONDONE
    end
    if length(ls[1])>0
        if ls[1][1] in "|0123456789"
            @goto TRANSACTIONDONE
        end
    end
    push!(text,popfirst!(ls))
    @goto TRANSACTIONTEXT2
    
    @label TRANSACTIONDONE
    t=Transaction(id,date,amount,matchinfo,text)
    push!(ledgercontents,t)
    transactions[t.id]=t
    @goto START
    
    @label DONE
    return ledgercontents,transactions
end


function writeledgerfile(fname,contents)
    f=open(fname,"w")
    for x in contents
        write(f,tostring(x))
    end
    close(f)
end


end
