# views.py
from django.shortcuts import render, redirect
from django.db import connection
from .utils import execute_raw_sql_query, group_checker
from django.shortcuts import render
from .forms import *
from django.contrib.auth import login, logout, authenticate
# widok strony domowej
def home(request):
    return render(request, 'main/home.html', {'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})
# widok ERD
def erd(request):
    return render(request, 'main/erd.html', {'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})
# widok dokumentacji
def dokumentacja(request):
    return render(request, 'main/dokumentacja.html', {'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})
# widok widok Sktrptu SQL
def skrypt(request):
    return render(request, 'main/script.html', {'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})
# widok Poleceń własnych
def display_data(request):
    query = request.GET.get('query', '')
    
    if query:
        try:
            # Attempt to execute the raw SQL query using the function
            results = execute_raw_sql_query(query)

            # Pass the query and results to the template
            return render(request, 'db/admin_bar.html', {'query': query, 'results': results})
        except Exception as e:
            # Handle exceptions (e.g., invalid SQL syntax)
            error_message = f"Error executing query: {str(e)}"
            if error_message == "Error executing query: 'NoneType' object is not iterable":
                return render(request, 'db/admin_bar.html', {'query': query})
            return render(request, 'db/admin_bar.html', {'query': query, 'error_message': error_message})
    else:
        return render(request, 'db/admin_bar.html', {'query': None, 'results': None})

# widok SELECT
def select(request):
    selected_option = request.GET.get('query')

    if selected_option == '1':
        query = 'select * from projekt.rybak r order by r.nazwisko'
        results = execute_raw_sql_query(query)
    elif selected_option == '2':
        query = 'select * from projekt.zbiornik z order by z.nazwa'
        results = execute_raw_sql_query(query)
    elif selected_option == '3':
        query = 'select * from projekt.rynek'
        results = execute_raw_sql_query(query)
    elif selected_option == '4':
        query = 'select * from projekt.oddzial o order by o.nazwa'
        results = execute_raw_sql_query(query)
    elif selected_option == '5':
        query = 'select * from projekt.zwierze z order by z.nazwa'
        results = execute_raw_sql_query(query)
    elif selected_option == '6':
        query = 'select * from projekt.straznik s order by s.nazwisko'
        results = execute_raw_sql_query(query)
    elif selected_option == '7':
        query = 'select z.gatunek, count(*) as "ilość zwierząt" from projekt.zwierze z group by z.gatunek order by z.gatunek'
        results = execute_raw_sql_query(query)
    elif selected_option == '8':
        query = 'select * from projekt.zbiornik zb where zb.legalny = false'
        results = execute_raw_sql_query(query)
    elif selected_option == '9':
        query = 'select * from projekt.rybak r where r.wiek > 30 order by r.nazwisko'        
        results = execute_raw_sql_query(query)
    elif selected_option == '10':
        query = 'select distinct r.imie, r.nazwisko, sum(l.ilosc) as ilość from projekt.rybak r join projekt.lista l on r.rybak_id = l.rybak group by r.imie, r.nazwisko having sum(l.ilosc) >= 20 order by r.imie, r.nazwisko'
        results = execute_raw_sql_query(query)
    elif selected_option == '11':
        query = 'select * from projekt.lista'
        results = execute_raw_sql_query(query)
    elif selected_option == '12':
        query = "select r.imie, r.nazwisko, l.zwierze, l.ilosc from projekt.lista l join projekt.rybak r on r.rybak_id = l.rybak where r.imie like 'A%'"
        results = execute_raw_sql_query(query)
    elif selected_option == '13':
        query = 'select r.nazwa, cast(avg(rz.cena) as numeric(6, 2)) as "średnia cena" from projekt.rynek r join projekt.rynek_zwierze rz on r.nazwa = rz.rynek group by r.nazwa order by r.nazwa desc'
        results = execute_raw_sql_query(query)
    else:
        query = ''
        results = []

    return render(request, 'db/show.html', {'results': results, 'query': query, 'is_rybak': group_checker(request, 'rybak'), 'straznik': group_checker(request, 'straznik')})
# widok DELETE
def delete(request):
    if request.method == 'POST':
        if 'delete_rybak_imie' in request.POST:
            imie = request.POST['rybak_imie']
            query = f"delete from projekt.rybak where imie like '{str(imie)}%'"

        elif 'delete_rybak_ryby' in request.POST:
            ilosc = request.POST['rybak_ryby']
            query = f"delete from projekt.rybak where rybak_id in (select l.rybak from projekt.lista l group by l.rybak having sum(l.ilosc) > {str(ilosc)})"

        elif 'delete_rybak_wiek' in request.POST:
            wiek = request.POST['rybak_wiek']
            query = f"delete from projekt.rybak where wiek > {str(wiek)}"

        elif 'delete_lista_legalne' in request.POST:
            legalne = request.POST.get('lista_legalne', False)
            if legalne == 'on':
                legalne = True
            else:
                legalne = False
            query = f"delete from projekt.lista where zwierze in (select z.nazwa from projekt.zwierze z where z.legalna = {str(legalne)})"

        else:
            query = ''

        try:
            # Attempt to execute the raw SQL query using the function
            execute_raw_sql_query(query)

            # Pass the query and results to the template
            return render(request, 'db/delete.html', {'query': query, 'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})
        except Exception as e:
            # Handle exceptions (e.g., invalid SQL syntax)
            error_message = f"{str(e).split('CONTEXT')[0]}"
            if error_message == "'NoneType' object is not iterable":
                return render(request, 'db/delete.html', {'query': query, 'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})
            return render(request, 'db/delete.html', {'query': query, 'error_message': error_message, 'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})
    return render(request, 'db/delete.html', {'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})
# widok Zresetuj dane w bazie
def rewrite(request):
    query = f"select * from rewrite_db()"
    execute_raw_sql_query(query)
    return render(request, 'main/home.html', {'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})
# widok Rejestracji nowego konta
def sign_up(request):
    if request.method == 'POST':
        form = RegisterForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user)
            return redirect('/home')
    else:
        form = RegisterForm()

    return render(request, 'registration/sign_up.html', {'form': form})
# widok Wylogowania się
def custom_logout(request):
    logout(request)
    return redirect('/login') 


# widok INSERT
def insert(request):
    if request.method == 'POST':
        if 'submit_rybak' in request.POST:
            imie = request.POST['rybak_imie']
            nazwisko = request.POST['rybak_nazwisko']
            wiek = request.POST['rybak_wiek']
            stan_konta = request.POST['rybak_stan_konta']
            licencja_id = request.POST['rybak_licencja_id']
            if licencja_id:
                query = f"insert into projekt.rybak (imie, nazwisko, wiek, stan_konta, licencja_id) values ('{str(imie)}', '{str(nazwisko)} ', {str(wiek)}, {str(stan_konta)}, {str(licencja_id)})"
            else:
                query = f"insert into projekt.rybak (imie, nazwisko, wiek, stan_konta) values ('{str(imie)}', '{str(nazwisko)} ', {str(wiek)}, {str(stan_konta)})"
                        
        elif 'submit_licencja' in request.POST:
            data_startu = request.POST['licencja_data_startu']
            data_konca = request.POST['licencja_data_konca']
            query = f"insert into projekt.licencja (data_startu, data_konca) values ('{str(data_startu)}', '{str(data_konca)}')"

        elif 'submit_lista' in request.POST:
            rybak_id = request.POST['lista_rybak_id']
            zwierze = request.POST['lista_zwierze']
            ilosc_ryb = request.POST['lista_ilosc_ryb']
            query = f"insert into projekt.lista (rybak, zwierze, ilosc) values ({str(rybak_id)}, '{str(zwierze)}', {str(ilosc_ryb)})"

        elif 'submit_oddzial_glowny' in request.POST:
            nazwa = request.POST['oddzial_glowny_nazwa']
            query = f"insert into projekt.oddzial_glowny (nazwa) values ('{str(nazwa)}')"

        elif 'submit_straznik' in request.POST:
            imie = request.POST['straznik_imie']
            nazwisko = request.POST['straznik_nazwisko']
            wiek = request.POST['straznik_wiek']
            oddzial = request.POST['straznik_oddzial_id']
            query = f"insert into projekt.straznik (imie, nazwisko, wiek, oddzial_id) values ('{str(imie)}', '{str(nazwisko)}', {str(wiek)}, '{str(oddzial)}')"

        elif 'submit_oddzial' in request.POST:
            nazwa = request.POST['oddzial_nazwa']
            oddzial_nadrzedny = request.POST['oddzial_oddzial_nadrzedny']
            query = f"insert into projekt.oddzial (nazwa, oddzial_nadrzedny) values ('{str(nazwa)}', '{str(oddzial_nadrzedny)}')"

        elif 'submit_zbiornik' in request.POST:
            nazwa = request.POST['zbiornik_nazwa']
            objetosc = request.POST['zbiornik_objetosc']
            if request.POST.get('zbiornik_legalny', False) == 'on':
                legalny = True
            else: 
                legalny = False
            oddzial = request.POST['zbiornik_oddzial']
            query = f"insert into projekt.zbiornik (nazwa, objetosc, legalny, oddzial) values ('{str(nazwa)}', {str(objetosc)}, {str(legalny)},'{str(oddzial)}')"

        elif 'submit_rynek' in request.POST:
            nazwa = request.POST['rynek_nazwa']
            oddzial_glowny = request.POST['rynek_oddzial_glowny']
            query = f"insert into projekt.rynek (nazwa, oddzial_glowny) values ('{str(nazwa)}', '{str(oddzial_glowny)}')"

        elif 'submit_zwierze' in request.POST:
            nazwa = request.POST['zwierze_nazwa']
            gatunek = request.POST['zwierze_gatunek']
            if request.POST.get('zwierze_legalna', False) == 'on':
                legalny = True
            else: 
                legalny = False
            query = f"insert into projekt.zwierze (nazwa, gatunek, legalna) values ('{str(nazwa)}', '{str(gatunek)}', {str(legalny)})"

        elif 'submit_rynek_zwierze' in request.POST:
            rynek = request.POST['rynek_zwierze_rynek']
            zwierze = request.POST['rynek_zwierze_zwierze']
            cena = request.POST['rynek_zwierze_cena']
            query = f"insert into projekt.rynek_zwierze (rynek, zwierze, cena) values ('{str(rynek)}', '{str(zwierze)}', {str(cena)})"

        elif 'submit_zwierze_zbiornik' in request.POST:
            zbiornik = request.POST['zwierze_zbiornik_zbiornik']
            zwierze = request.POST['zwierze_zbiornik_zwierze']
            query = f"insert into projekt.zwierze_zbiornik (zwierze, zbiornik) values ('{str(zwierze)}', '{str(zbiornik)}')"

        else:
            query = ''

        try:
            # Attempt to execute the raw SQL query using the function
            execute_raw_sql_query(query)

            # Pass the query and results to the template
            return render(request, 'db/insert.html', {'query': query, 'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})
        except Exception as e:
            # Handle exceptions (e.g., invalid SQL syntax)
            error_message = f"{str(e).split('CONTEXT')[0]}"
            if error_message == "'NoneType' object is not iterable":
                return render(request, 'db/insert.html', {'query': query, 'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})
            return render(request, 'db/insert.html', {'query': query, 'error_message': error_message, 'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})

    return render(request, 'db/insert.html', {'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})
# widok SPECIAL
def special(request):
    if request.method == 'POST':
        if 'submit_special_rybak' in request.POST:
            rybak_id = request.POST.get('rybak_id_special', '')
            sklep_id = request.POST.get('sklep_id_special', '')
            
            query = f"select * from sell_animals({str(rybak_id)},'{str(sklep_id)}')"

        if 'submit_special_straznik' in request.POST:
            rybak_id = request.POST.get('rybak_id_special', '')
            straznik_id = request.POST.get('straznik_id_special', '')
            
            query = f"select * from check_rybak_licence({str(rybak_id)},'{str(straznik_id)}')"

        try:
            # Attempt to execute the raw SQL query using the function
            execute_raw_sql_query(query)

            # Pass the query and results to the template
            return render(request, 'db/special.html', {'query': query, 'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})
        except Exception as e:
            # Handle exceptions (e.g., invalid SQL syntax)
            error_message = f"{str(e).split('CONTEXT')[0]}"
            if error_message == "'NoneType' object is not iterable":
                return render(request, 'db/special.html', {'query': query, 'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})
            return render(request, 'db/special.html', {'query': query, 'error_message': error_message, 'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})
    return render(request, 'db/special.html', {'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})
