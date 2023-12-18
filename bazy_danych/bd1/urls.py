from django.urls import path
from . import views

urlpatterns =[
    path('', views.home, name='home'),
    path('home', views.home, name='home'),
    path('own_query', views.display_data, name='own_query'),
    path('dokumentacja', views.dokumentacja, name='dokumentacja'),
    path('erd', views.erd, name='erd'),
]