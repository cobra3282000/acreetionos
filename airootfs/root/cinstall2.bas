$ScreenHide
$Console
_Dest _Console

Rem ask for name and create the user name and dictories now.

Cls

over1:

Print
Print

Print "Create your user account!"

Print


Do While name$ = ""
    Line Input "Your name please? ", name$
Loop

fullname$ = LCase$(name$)

xx = InStr(fullname$, " ")

name$ = Mid$(fullname$, 1, xx - 1)

loop9:

pass$ = "123"
p2$ = "fcku"

Print
Do While pass$ <> p2$

    Line Input "Password: ", pass$

    Line Input "Verify Password: ", p2$

Loop

Print
Print "Use " + name$ + " as your username?  (Y/n): "

Line Input aa$

If aa$ = "n" Or aa$ = "N" Then

    Print
    Line Input "Username: ", name$
    If name$ = "" Then
        Print "Cant be blank, sorry!"
        GoTo over1:
    End If
End If

Print
Print "Creating User Account: "; name$

Rem creating user accounts!

Shell "mkdir /home/" + name$
xx$ = "mkdir /home/" + name$
Shell xx$
bb$ = xx$

xx$ = bb$ + "/Documents"
Shell xx$
Print xx$

xx$ = bb$ + "/Templates"
Shell xx$
Print xx$

xx$ = bb$ + "/Downloads"
Shell xx$
Print xx$

xx$ = bb$ + "/Videos"
Shell xx$
Print xx$

xx$ = bb$ + "/Pictures"
Shell xx$
Print xx$
xx$ = bb$ + "/Public"
Shell xx$
Print xx$

xx$ = bb$ + "/Desktop"
Shell xx$
Print xx$

Print
Print "Adding user to system now, including wheel group for SUDO powers."
Print

Shell "useradd " + name$ + " -b /home/" + name$ + " -p " + pass$ + " -G wheel"
Shell ""


