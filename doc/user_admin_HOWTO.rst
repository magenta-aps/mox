
Oprettelse af brugere i referencedata.dk
========================================


Find brugerstyringen
++++++++++++++++++++

Gå ind på WSO2-serveren, https://referencedata.dk:9443

Du skulle gerne være på fanebladet "Configure", se den lodrette liste af
faneblade helt ude til venstre. I "Configure"-menuen øverst til venstre
klikker du på "Users and Roles" for at komme ind i brugerstyringen.

Under menupunktet "System User Store" klikker du på "Users" for at gå
ind i listen af brugere.

Opret bruger
++++++++++++

Opret
-----

Under listen af brugere finder du et grønt plus, til højre for hvilket
der står "Add New User". Klik på dette.

Udfyld feltet "User Name" og lad radioknappen blive stående på "Define
password here". Udfyld felterne "Password" og "Password repeat" med  et
password, som du efterfølgende skal sende til brugeren.

Den anden mulighed, "Ask password from user", virker p.t. ikke.


Klik "Next". Du kan nu vælge en rolle til den nye gruppe. Vælg
"Internal/readonly" for at give læseadgang eller "Internal/mox" for at
give både læse- og skriveadgang. Såfremt din nye bruger skal have adgang
til at logge ind på WSO2 Identity Server (altså der, hvor du selv lige
er logget ind), skal du også tildele den rollen "admin". Dette kan du
kun gøre, hvis du er logget ind som brugeren admin, der fungerer som
master-bruger. De andre profiler kan du tildele, blot du selv har
admin-rollen.

Vælg "Finish" for at færdiggøre oprettelsen af brugeren.

Brugeren er nu oprettet, men kan endnu ikke tildeles et validt
SAML-token.

Rediger profil
--------------

Find din nyoprettede bruger i listen af brugere. Brug eventuelt
søgefeltet, hvis du finder listen uoverskuelig.

Vælg "User Profile" for at redigere brugerprofilen. Udfyld felterne
"First Name", "Last Name", "Email" og "URL".

I feltet URL *skal* der stå en UUID, som er brugerens UUID i
Organisation. Hvis brugeren endnu ikke eksisterer i Organisation, kan du
oprette den med det regneark, der er udleveret af Leif Lodahl. Hvis
brugeren af en eller anden grund  ikke skal oprettes i Organisation, kan
du skrive en hvilken som helst gyldig UUID.

Klik Update.

Hvis alt gik godt, kan din bruger nu få udstedt et SAML-token til
referencedata.dk med det password, du har angivet.


Ret bruger
++++++++++

For en given bruger har du mulighed for at ændre vedkommendes password,
tildele og fjerne roller samt redigere brugerprofilen.

Vi vil herunder gennemgå nogle af de vigtigste scenarier set fra et
referencedata.dk-perspektiv.

Skifte password
---------------

Find den ønskede bruger i listen af brugere. Brug eventuelt
søgefunktionen. 

Ud for brugeren klikker du på "Change Password". Udfyld felterne "New
Password" og "New Password Repeat" og klik på "Change".

Brugeren kan nu bruge det nye password.

Give læseadgang
---------------

Find den ønskede bruger i listen af brugere. Brug eventuelt
søgefunktionen. 

Ud for brugeren klikker du på "Assign Roles". Sæt flueben i
"Internal/readonly" og klik på "Update". 

Klik på "Finish" for at gå tilbage til listen af brugere.

Hvis brugeren allerede havde læse/skrive-adgang og ikke længere skal
have det, skal du klikke på "View Roles" ud for brugeren. Hvis
læseadgang er tildelt korret, vil du se, at der er flueben i rollen
"Internal/readonly". Fjern fluebenet i rollen "Internal/mox", hvis det
er der. 

* Bemærk, at ændringen først slår igennem næste gang, brugeren får
  udstedt et token.


Give skriveadgang
------------------

Find den ønskede bruger i listen af brugere. Brug eventuelt
søgefunktionen. 

Ud for brugeren klikker du på "Assign Roles". Sæt flueben i
"Internal/mox" og klik på "Update". 

Klik på "Finish" for at gå tilbage til listen af brugere.

* Bemærk, at ændringen først slår igennem næste gang, brugeren får
  udstedt et token.


Blokere bruger
--------------

Find den ønskede bruger i listen af brugere. Brug eventuelt
søgefunktionen. 

Ud for brugeren klikker du på "Assign Roles". Sæt flueben i
"Internal/blokeret" og klik på "Update". 

Klik på "Finish" for at gå tilbage til listen af brugere.

* Bemærk, at ændringen først slår igennem næste gang, brugeren får
  udstedt et token.

* Bemærk, at dette kun blokerer brugeren fra at bruge services på
  referencedata.dk. Hvis vedkommende også skal blokeres for at logge ind
  på WSO2 Identity Server, er det nødvendigt at fjerne rollen
  "Internal/admin" fra brugeren.


Tildele admin-rolle (og adgang til WSO2 Identity Server)
--------------------------------------------------------

Log ind som brugeren admin. Hvis du ikke har password til denne bruger,
skal du enten ikke have det, eller også ved du allerede, hvem du skal
spørge om det.

Find den ønskede bruger i listen af brugere. Brug eventuelt
søgefunktionen. 

Ud for brugeren klikker du på "Assign Roles". Sæt flueben i
"admin" og klik på "Update". 

Klik på "Finish" for at gå tilbage til listen af brugere.


Fjerne admin-rolle (og adgang til WSO2 Identity Server)
-------------------------------------------------------

Log ind som brugeren admin. Hvis du ikke har password til denne bruger,
skal du enten ikke have det, eller også ved du allerede, hvem du skal
spørge om det.

Find den ønskede bruger i listen af brugere. Brug eventuelt
søgefunktionen. 

Ud for brugeren klikker du på "View Roles".

Fjern fluebenet ud for rollen "admin".

Klik på "Update" og klik herefter på "Finish" for at gå tilbage til
listen af brugere.

