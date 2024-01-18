from django.db import connection
from django.contrib.auth.models import User, Group

# funkcja do wykonywania poleceń SQL
def execute_raw_sql_query(query, params=None):
    with connection.cursor() as cursor:
        if params:
            cursor.execute(query, params)
        else:
            cursor.execute(query)

        # Fetch the results
        columns = [col[0] for col in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]
        
    return results

# funkcja do sprawdzania przynależności użytkownika do danej grupy
def group_checker(request, name):
    return request.user.groups.filter(name=name).exists()