# views.py
from django.shortcuts import render, HttpResponse
from django.db import connection
from .utils import execute_raw_sql_query
from django.shortcuts import render

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
