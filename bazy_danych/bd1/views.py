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
            return render(request, 'db/admin_bar.html', {'query': query, 'error_message': error_message})
    else:
        return render(request, 'db/admin_bar.html', {'query': None, 'results': None})


def select(request):
    selected_option = request.GET.get('query', '')
    
    if selected_option == 1:
        query = 'select * from projekt.rybak'
        results = execute_raw_sql_query(query)
    elif selected_option == 2:
        query = 'select * from projekt.zbiornik'
        results = execute_raw_sql_query(query)
    elif selected_option == 3:
        query = 'select * from projekt.rynek'
        results = execute_raw_sql_query(query)
    elif selected_option == 4:
        query = 'select * from projekt.oddzial'
        results = execute_raw_sql_query(query)
    elif selected_option == 5:
        query = 'select * from projekt.rybak r where r.wiek > 30'
        results = execute_raw_sql_query(query)
    elif selected_option == 6:
        query = 'select * from projekt.rybak r where (select count(*) from projekt.lista l where r.rybak_id = l.rybak_id) > 4'
        results = execute_raw_sql_query(query)
    else:
        query = 'select * from projekt.zbiornik'
        results = execute_raw_sql_query(query)


    return render(request, 'db/show.html', {'results': results, 'query': query, 'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'is_straznik')})

def update(request):
    return render(request, 'db/update.html', {'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'is_straznik')})

def delete(request):
    return render(request, 'db/delete.html', {'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'is_straznik')})

def insert(request):
    return render(request, 'db/insert.html', {'is_rybak': group_checker(request, 'rybak'), 'is_straznik': group_checker(request, 'is_straznik')})

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