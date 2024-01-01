# views.py
from django.shortcuts import render, redirect
from django.db import connection
from .utils import execute_raw_sql_query, group_checker
from django.shortcuts import render
from .forms import *
from django.contrib.auth import login, logout, authenticate
# Create your views here.
def home(request):
    return render(request, 'main/home.html')

def erd(request):
    return render(request, 'main/erd.html')

def dokumentacja(request):
    return render(request, 'main/dokumentacja.html')

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


def select(request):
    selected_option = request.GET.get('query', '')
    
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
        query = 'select distinct r.imie, r.nazwisko, sum(l.ilosc) as ilość from projekt.rybak r join projekt.lista l on r.rybak_id = l.rybak where (select sum(l2.ilosc) from projekt.lista l2 where l2.rybak = r.rybak_id) >= 20 group by r.imie, r.nazwisko order by r.imie, r.nazwisko'
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
    elif selected_option == '14':
        query = ''
        results = execute_raw_sql_query(query)
    else:
        query = ''
        results = []


    return render(request, 'db/show.html', {'results': results, 'query': query, 'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'straznik')})

def update(request):
    return render(request, 'db/update.html', {'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'is_straznik')})

def delete(request):
    return render(request, 'db/delete.html', {'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'is_straznik')})


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

def custom_logout(request):
    logout(request)
    return redirect('/login') 



def insert(request):
    if request.method == 'POST':
        if 'submit_rybak' in request.POST:
            imie = request.POST['rybak_imie']
            nazwisko = request.POST['rybak_nazwisko']
            wiek = request.POST['rybak_wiek']
            stan_konta = request.POST['rybak_stan_konta']
            query = "insert into projekt.rybak (imie, nazwisko, wiek, stan_konta) values ('" + str(imie) + "', '" + str(nazwisko) + "', " + str(wiek) + ", " + str(stan_konta) + ")"
                        
        elif 'submit_lista' in request.POST:
            rybak_id = request.POST['lista_rybak_id']
            zwierze = request.POST['lista_zwierze']
            ilosc_ryb = request.POST['lista_ilosc_ryb']
            query = f"insert into projekt.lista (rybak, zwierze, ilosc) values ({str(rybak_id)}, '{str(zwierze)}', {str(ilosc_ryb)})"

        try:
            # Attempt to execute the raw SQL query using the function
            execute_raw_sql_query(query)

            # Pass the query and results to the template
            return render(request, 'db/insert.html', {'query': query, 'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'is_straznik')})
        except Exception as e:
            # Handle exceptions (e.g., invalid SQL syntax)
            error_message = f"Error executing query: {str(e)}"
            if error_message == "Error executing query: 'NoneType' object is not iterable":
                return render(request, 'db/insert.html', {'query': query, 'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'is_straznik')})
            return render(request, 'db/insert.html', {'query': query, 'error_message': error_message, 'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'is_straznik')})

    return render(request, 'db/insert.html', {'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'is_straznik')})