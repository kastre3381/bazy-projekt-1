from django.urls import path
from . import views
from django.contrib.auth.views import LogoutView

urlpatterns =[
    path('', views.home, name='home'),
    path('home', views.home, name='home'),
    path('skrypt/', views.skrypt, name='skrypt'),
    path('own_query/', views.display_data, name='own_query'),
    path('dokumentacja/', views.dokumentacja, name='dokumentacja'),
    path('erd/', views.erd, name='erd'),
    path('sign-up/', views.sign_up, name='sign_up'),
    path('logout/', views.custom_logout, name='logout'),
    path('select/', views.select, name='select'),
    path('delete/', views.delete, name='delete'),
    path('insert/', views.insert, name='insert'),
    path('update/', views.update, name='update'),
    path('special/', views.special, name='special'),
]