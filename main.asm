; Napíšte program (v JSI) ktorý umožní používateľovi pomocou argumentov zadaných na príkazovom riadku pri 
; spúšťaní programu vykonať pre zadaný súbor/súbory (vstup) vybranú funkciu (viď. nižšieúlohy 1-20). Ak bude 
; zadaný prepínač '-h', program musí zobraziť informácie o programe a jeho použití. V programe vhodne použite 
; makro s parametrom, ako aj vhodné volania OS (resp. BIOS) pre nastavenie kurzora, výpis reťazca, zmazanie 
; obrazovky, prácu so súbormi a pod. Definície makier musia byť v samostatnom súbore. Program musí korektne 
; spracovať súbory s dĺžkou aspoň do 64 kB. Pri čítaní využite pole vhodnej veľkosti (buffer), pričom zo súboru 
; do pamäte sa bude opakovane presúvať vždy (až na posledné čítanie) celáveľkosť poľa. Ošetrite chybové  stavy.  
; Program,  respektíve  každý  zdrojový  súbor,  musí  obsahovať primeranú technickú dokumentáciu

; Úloha:
; 1. Vypísať počty číslic, malých písmen, veľkých písmen a ostatných znakov pre každý riadok aj pre celý vstup.

; Decentne vypracované:
; 9. Plus 2 body: Ak bude možné zadať viacero vstupných súborov.
;                 Každý súbor je samostatne spracovaný (neexistuje teda napr. štatistika pre všetky vstupy, len pre jeden celý vstup - súbor).
; 12. Plus 1 bod je možné získať za (dobré) komentáre, resp. dokumentáciu, v anglickom jazyku.
;                 Program je kompletne komentovaný v anglickom jazyku (na výnimku tohto úvodu, keďže zadanie bolo v slovenčine :) ).
; 10. Plus 2 body je možné získať ak pridelená úloha bude realizovaná ako externá procedúra (kompilovaná samostatne a prilinkovaná k výslednému programu)
;                 Viď count.asm: kompilácia, linkovanie aj samotný program zbehne bez problémov, aj keď nie úplne rozumiem všetkým detailom.

; Ako-tak vypracované:
; 7. Plus 1 bod: Ak budú korektne spracované vstupné súbory s veľkosťou nad 64 kB.
;                Funguje, ale pretečie counter pre štatistiky jemne nad 64kB kvôli 16-bit limitu (ak je napr celý súbor na vstupe plný jedného znaku)
;                Je to skôr technická limitácia spôsobená tým, že som sa rozhodol zapisovať/vypisovať štatistiky ako číslo a nie reťazec.
; 11. Plus 1 bod je možné získať za (zmysluplné) použitie reťazcových inštrukcií (MOVS, CMPS, STOS, etc.)
;                Použitý 3x CMPS ale ostatné nie.

; Nevypracované:
; Pôvodne som chcel riešiť aj stránkovanie a bonusové úlohy s ním spojené, ale na to nie je čas. Viem len, že BIOS má prístupnú vhodnú scroll funkcionalitu. :(

; Nejaké zhodnotenie:
; Zadanie hodnotim ako časovú nočnú moru, spočiatku sa mi do toho naozaj nechcelo, ale teraz keď som rozbehnutý tak je to vcelku zábavka. 7/10 would do it again, maybe.


; The whole program supplied as an external procedure (count.asm), separately compiled and then linked.
; See / use compile.bat for compilation and linking.
; Ondrej Spanik 2022 iairu.com

_ZAS   SEGMENT
        DW      8 DUP(?)
_ZAS   ENDS

EXTRN count:PROC            ; Defines external procedure to be compiled

_CODE SEGMENT
    ASSUME CS:_CODE, DS:_CODE

start:
    call count              ; Starts the external procedure

_CODE ENDS
    END start
    