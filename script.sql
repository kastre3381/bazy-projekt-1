create schema projekt;

create or replace function random_generator(minimum integer, maximum integer) returns integer as 
$$
begin 
	return FLOOR(RANDOM() * (maximum - minimum + 1) + minimum);
end
$$
language plpgsql;

create table projekt.oddzial_glowny
(
	nazwa varchar not null,
	constraint oddzial_glowny_pk primary key (nazwa)
);

 create table projekt.oddzial
(
	nazwa varchar not null,
	oddzial_nadrzedny varchar not null,
	constraint oddzial_pk primary key (nazwa),
	constraint oddzial_fk foreign key(oddzial_nadrzedny) references projekt.oddzial_glowny(nazwa) on delete cascade
);

create table projekt.straznik
(
	straznik_id serial,
	imie varchar not null,
	nazwisko varchar not null,
	wiek integer not null,
	oddzial_id varchar not null,
	constraint straznik_pk primary key (straznik_id),
	constraint straznik_fk foreign key (oddzial_id) references projekt.oddzial(nazwa) on delete cascade
);


 create table projekt.licencja
 (
	licencja_id serial,
	data_startu date not null,
	data_konca date not null,
	constraint licencja_pk primary key (licencja_id)
 );

create table projekt.rybak
(
	rybak_id serial,
	imie varchar not null,
	nazwisko varchar not null,
	stan_konta numeric(10,2) not null,
	wiek integer not null,
	licencja_id integer,
	constraint rybak_pk primary key (rybak_id),
	constraint rybak_fk foreign key (licencja_id) references projekt.licencja(licencja_id) on delete cascade
);



create or replace function create_licence()
returns trigger as
$$
declare 
czy_tworzyc_licencje integer;
ile_lat_wazna integer;
begin 
	czy_tworzyc_licencje := random_generator(0, 3);
	if czy_tworzyc_licencje = 0 then
		return new;
	else
		ile_lat_wazna := random_generator(1, 10000);
		insert into projekt.licencja (data_startu, data_konca) values (CURRENT_DATE, CURRENT_DATE + ile_lat_wazna);
		new.licencja_id := (select max(l.licencja_id) from projekt.licencja l);
		return new;
	end if;
end
$$
language plpgsql;

create trigger licence_creator before insert on projekt.rybak for each row execute procedure create_licence();



create table projekt.zbiornik
(
	nazwa varchar not null,
	objetosc integer not null,
	legalny bool not null,
	oddzial varchar not null,
	constraint zbiornik_pk primary key (nazwa),
	constraint zbiornik_fk foreign key (oddzial) references projekt.oddzial(nazwa) on delete cascade
);

create or replace function legal_setter() returns trigger as 
$$
begin 
	if random_generator(0, 1) then
		new.legalny := true;
	else 
		new.legalny = false;
	end if;
	return new;
end
$$
language plpgsql;

create trigger legal_setter before insert on projekt.zbiornik for each row execute procedure legal_setter();

 create table projekt.zwierze
 (
	nazwa varchar not null,
	gatunek varchar not null,
	legalna boolean not null,
	constraint zwierze_pk primary key (nazwa)
 );

create table projekt.zwierze_zbiornik
(
	zwierze_zbiornik_id serial,
	zwierze varchar not null,
	zbiornik varchar not null,
	constraint zwierze_zbiornik_pk primary key(zwierze_zbiornik_id),
	constraint zwierze_fk foreign key (zwierze) references projekt.zwierze(nazwa) on delete cascade,
	constraint zbiornik_fk foreign key (zbiornik) references projekt.zbiornik(nazwa) on delete cascade
);

create or replace function add_animals() returns trigger as 
$$
begin 
	insert into projekt.zwierze_zbiornik (zwierze, zbiornik) select z.nazwa, new.nazwa from projekt.zwierze z order by random() limit random_generator(10, 30);
return new;
end
$$
language plpgsql;

create trigger animal_adder after insert on projekt.zbiornik for each row execute procedure add_animals();

 create table projekt.lista
 (
	lista_id serial,
	zwierze varchar not null,
	rybak integer not null,
	ilosc integer not null,
	constraint lista_pk primary key(lista_id),
	constraint zwierze_fk foreign key (zwierze) references projekt.zwierze(nazwa) on delete cascade,
	constraint rybak_fk foreign key (rybak) references projekt.rybak(rybak_id) on delete cascade
 );

create or replace function rybak_delete() returns trigger as 
$$
begin 
	if old.licencja_id in (select l.licencja_id from projekt.licencja l where l.licencja_id = old.licencja_id) then
		delete from projekt.licencja where old.licencja_id = licencja_id;
	end if;
	delete from projekt.lista  where old.rybak_id = rybak;
	return old;
end
$$
language plpgsql;


create trigger rybak_delete after delete on projekt.rybak for each row execute procedure rybak_delete();
 
create or replace function create_list() returns trigger as 
$$
begin 
	insert into projekt.lista (zwierze, rybak, ilosc) select z.nazwa, cast(new.rybak_id as integer), random_generator(1, 5) from projekt.zwierze z where z.nazwa in 
											    (select z2.nazwa from projekt.zwierze z2 order by random() limit random_generator(0, 20));
	return new;										  
end
$$
language plpgsql;

create trigger list_creator after insert on projekt.rybak for each row execute procedure create_list();


create table projekt.rynek
(
	nazwa varchar not null,
	oddzial_glowny varchar not null,
	constraint rynek_pk primary key (nazwa),
	constraint oddzial_fk foreign key (oddzial_glowny) references projekt.oddzial_glowny(nazwa) on delete cascade
);

create table projekt.rynek_zwierze
(
	rynek_zwierze_id serial,
	rynek varchar not null,
	zwierze varchar not null,
	cena numeric(10, 2) not null,
	constraint rynek_zwierze_pk primary key (rynek_zwierze_id),
	constraint rynek_fk foreign key (rynek) references projekt.rynek(nazwa),
	constraint zwierze_fk foreign key (zwierze) references projekt.zwierze(nazwa) on delete cascade
);

create or replace function add_to_market() returns trigger as 
$$
declare 
rec record;
begin 
	insert into projekt.rynek_zwierze (rynek, zwierze, cena) select new.nazwa, z.nazwa, cast(random_generator(1, 10000) as float)/100  from projekt.zwierze z;
	return new;
end
$$
language plpgsql;

create trigger market_price_adder after insert on projekt.rynek for each row execute procedure add_to_market();

--------------- dodawanie danych do bazy ---------------------------


INSERT INTO projekt.oddzial_glowny (nazwa) VALUES
  ('Polska'),
  ('Niemcy'),
  ('Francja');
 
INSERT INTO projekt.oddzial (nazwa, oddzial_nadrzedny) VALUES
  ('Dolnośląskie', 'Polska'),
  ('Kujawsko-Pomorskie', 'Polska'),
  ('Lubelskie', 'Polska'),
  ('Lubuskie', 'Polska'),
  ('Łódzkie', 'Polska'),
  ('Małopolskie', 'Polska'),
  ('Mazowieckie', 'Polska'),
  ('Opolskie', 'Polska'),
  ('Podkarpackie', 'Polska'),
  ('Podlaskie', 'Polska'),
  ('Pomorskie', 'Polska'),
  ('Śląskie', 'Polska'),
  ('Świętokrzyskie', 'Polska'),
  ('Warmińsko-Mazurskie', 'Polska'),
  ('Wielkopolskie', 'Polska'),
  ('Zachodniopomorskie', 'Polska');
 
INSERT INTO projekt.oddzial (nazwa, oddzial_nadrzedny) VALUES
  ('Badenia-Wirtembergia', 'Niemcy'),
  ('Bawaria', 'Niemcy'),
  ('Bekle', 'Niemcy'),
  ('Brandenburgia', 'Niemcy'),
  ('Hamburg', 'Niemcy'),
  ('Hesja', 'Niemcy'),
  ('Meklemburgia-Pomorze Przednie', 'Niemcy'),
  ('Dolna Saksonia', 'Niemcy'),
  ('Nadrenia Północna-Westfalia', 'Niemcy'),
  ('Nadrenia-Palatynat', 'Niemcy'),
  ('Saara', 'Niemcy'),
  ('Saksonia', 'Niemcy'),
  ('Saksonia-Anhalt', 'Niemcy'),
  ('Szlezwik-Holsztyn', 'Niemcy'),
  ('Szwabia', 'Niemcy'),
  ('Turyngia', 'Niemcy'),
  ('Bremia', 'Niemcy');

INSERT INTO projekt.oddzial (nazwa, oddzial_nadrzedny) VALUES
  ('Wielka Prowansja-Alpy-Lazurowe Wybrzeże', 'Francja'),
  ('Oksytania', 'Francja'),
  ('Nowa Akwitania', 'Francja'),
  ('Normandia', 'Francja'),
  ('Hauts-de-France', 'Francja'),
  ('Île-de-France', 'Francja'),
  ('Grand Est', 'Francja'),
  ('Korsyka', 'Francja'),
  ('Bretania', 'Francja'),
  ('Paj-de-la-Loire', 'Francja'),
  ('Kraj Loary', 'Francja'),
  ('Burgundia-Franche-Comté', 'Francja'),
  ('Kraj Basków', 'Francja'),
  ('Kraj Nacjonalistów', 'Francja'),
  ('Centrum-Val de Loire', 'Francja'),
  ('Gwadelupa', 'Francja'),
  ('Martynika', 'Francja'),
  ('Gujana Francuska', 'Francja');

 

 
-- Wprowadź dane do tabeli projekt.straznik dla wszystkich polskich województw
INSERT INTO projekt.straznik (imie, nazwisko, wiek, oddzial_id) VALUES
  -- Dolnośląskie
  ('Jan', 'Kowalski', 30, 'Dolnośląskie'),
  ('Anna', 'Nowak', 28, 'Dolnośląskie'),
  ('Piotr', 'Wiśniewski', 35, 'Dolnośląskie'),

  -- Kujawsko-Pomorskie
  ('Karolina', 'Dąbrowska', 32, 'Kujawsko-Pomorskie'),
  ('Marek', 'Lewandowski', 29, 'Kujawsko-Pomorskie'),
  ('Ewa', 'Wójcik', 34, 'Kujawsko-Pomorskie'),

  -- Lubelskie
  ('Adam', 'Kowalczyk', 31, 'Lubelskie'),
  ('Agnieszka', 'Kamińska', 33, 'Lubelskie'),
  ('Grzegorz', 'Zieliński', 27, 'Lubelskie'),

  -- Lubuskie
  ('Zofia', 'Kowal', 29, 'Lubuskie'),
  ('Krzysztof', 'Jankowski', 32, 'Lubuskie'),
  ('Aleksandra', 'Szymańska', 30, 'Lubuskie'),

  -- Łódzkie
  ('Marcin', 'Nowacki', 33, 'Łódzkie'),
  ('Patrycja', 'Piotrowska', 28, 'Łódzkie'),
  ('Rafał', 'Kaczmarek', 31, 'Łódzkie'),

  -- Małopolskie
  ('Wojciech', 'Włodarczyk', 30, 'Małopolskie'),
  ('Monika', 'Kowalczyk', 29, 'Małopolskie'),
  ('Bartosz', 'Michalak', 34, 'Małopolskie'),

  -- Mazowieckie
  ('Katarzyna', 'Nowak', 32, 'Mazowieckie'),
  ('Michał', 'Kowal', 31, 'Mazowieckie'),
  ('Ewelina', 'Szymańska', 28, 'Mazowieckie'),

  -- Opolskie
  ('Tomasz', 'Lewandowski', 33, 'Opolskie'),
  ('Karolina', 'Nowak', 30, 'Opolskie'),
  ('Rafał', 'Kowalczyk', 29, 'Opolskie'),

  -- Podkarpackie
  ('Kamila', 'Wójcik', 32, 'Podkarpackie'),
  ('Daniel', 'Lewandowski', 28, 'Podkarpackie'),
  ('Natalia', 'Kowalska', 31, 'Podkarpackie'),

  -- Podlaskie
  ('Piotr', 'Zieliński', 34, 'Podlaskie'),
  ('Magdalena', 'Nowak', 29, 'Podlaskie'),
  ('Krzysztof', 'Kowalczyk', 27, 'Podlaskie'),

  -- Pomorskie
  ('Aleksandra', 'Kowalska', 30, 'Pomorskie'),
  ('Paweł', 'Lewandowski', 32, 'Pomorskie'),
  ('Karol', 'Kowalczyk', 28, 'Pomorskie'),

  -- Śląskie
  ('Natalia', 'Nowak', 29, 'Śląskie'),
  ('Bartłomiej', 'Kowalczyk', 31, 'Śląskie'),
  ('Katarzyna', 'Lewandowska', 28, 'Śląskie'),

  -- Świętokrzyskie
  ('Patrycja', 'Kowalczyk', 32, 'Świętokrzyskie'),
  ('Damian', 'Nowak', 30, 'Świętokrzyskie'),
  ('Sylwia', 'Wójcik', 29, 'Świętokrzyskie'),

  -- Warmińsko-Mazurskie
  ('Piotr', 'Kowalski', 33, 'Warmińsko-Mazurskie'),
  ('Marta', 'Nowak', 31, 'Warmińsko-Mazurskie'),
  ('Krzysztof', 'Lewandowski', 28, 'Warmińsko-Mazurskie'),

  -- Wielkopolskie
  ('Anna', 'Kowalska', 30, 'Wielkopolskie'),
  ('Mateusz', 'Nowak', 28, 'Wielkopolskie'),
  ('Karolina', 'Lewandowska', 32, 'Wielkopolskie'),

  -- Zachodniopomorskie
  ('Tomasz', 'Kowalczyk', 29, 'Zachodniopomorskie'),
  ('Monika', 'Lewandowska', 31, 'Zachodniopomorskie'),
  ('Kamil', 'Nowak', 28, 'Zachodniopomorskie');

 -- Wprowadź dane do tabeli projekt.straznik dla niemieckich krajów związkowych (landów)
INSERT INTO projekt.straznik (imie, nazwisko, wiek, oddzial_id) VALUES
  -- Badenia-Wirtembergia
  ('Hans', 'Schmidt', 30, 'Badenia-Wirtembergia'),
  ('Anna', 'Müller', 28, 'Badenia-Wirtembergia'),
  ('Stefan', 'Schneider', 35, 'Badenia-Wirtembergia'),

  -- Bawaria
  ('Monika', 'Fischer', 32, 'Bawaria'),
  ('Lukas', 'Weber', 29, 'Bawaria'),
  ('Sophie', 'Schulz', 34, 'Bawaria'),

  -- Bekle
  ('Tim', 'Wagner', 31, 'Bekle'),
  ('Laura', 'Schäfer', 33, 'Bekle'),
  ('Max', 'Koch', 27, 'Bekle'),

  -- Brandenburgia
  ('Leonie', 'Hoffmann', 29, 'Brandenburgia'),
  ('Paul', 'Schmidt', 32, 'Brandenburgia'),
  ('Lisa', 'Müller', 30, 'Brandenburgia'),

  -- Hamburg
  ('Finn', 'Schulz', 33, 'Hamburg'),
  ('Hannah', 'Meier', 28, 'Hamburg'),
  ('Nico', 'Schneider', 31, 'Hamburg'),

  -- Hesja
  ('Lara', 'Schmidt', 32, 'Hesja'),
  ('Jonas', 'Müller', 29, 'Hesja'),
  ('Elena', 'Weber', 34, 'Hesja'),

  -- Meklemburgia-Pomorze Przednie
  ('Luca', 'Hofmann', 33, 'Meklemburgia-Pomorze Przednie'),
  ('Sophia', 'Koch', 30, 'Meklemburgia-Pomorze Przednie'),
  ('David', 'Wagner', 29, 'Meklemburgia-Pomorze Przednie'),

  -- Dolna Saksonia
  ('Emma', 'Schulz', 32, 'Dolna Saksonia'),
  ('Benjamin', 'Müller', 28, 'Dolna Saksonia'),
  ('Mia', 'Fischer', 31, 'Dolna Saksonia'),

  -- Nadrenia Północna-Westfalia
  ('Julian', 'Schmidt', 29, 'Nadrenia Północna-Westfalia'),
  ('Sophie', 'Weber', 32, 'Nadrenia Północna-Westfalia'),
  ('Leon', 'Müller', 30, 'Nadrenia Północna-Westfalia'),

  -- Nadrenia-Palatynat
  ('Lena', 'Schulz', 33, 'Nadrenia-Palatynat'),
  ('Felix', 'Meier', 28, 'Nadrenia-Palatynat'),
  ('Lara', 'Schneider', 31, 'Nadrenia-Palatynat'),

  -- Saara
  ('Tom', 'Schmidt', 30, 'Saara'),
  ('Julia', 'Müller', 29, 'Saara'),
  ('Finn', 'Weber', 34, 'Saara'),

  -- Saksonia
  ('Sophie', 'Fischer', 31, 'Saksonia'),
  ('Noah', 'Schulz', 28, 'Saksonia'),
  ('Lukas', 'Meier', 29, 'Saksonia'),

  -- Saksonia-Anhalt
  ('Emily', 'Schmidt', 32, 'Saksonia-Anhalt'),
  ('Leon', 'Müller', 30, 'Saksonia-Anhalt'),
  ('Lara', 'Weber', 28, 'Saksonia-Anhalt'),

  -- Szwabia
  ('Mia', 'Hofmann', 29, 'Szwabia'),
  ('Max', 'Koch', 32, 'Szwabia'),
  ('Sophia', 'Wagner', 30, 'Szwabia'),

  -- Turyngia
  ('Luca', 'Schmidt', 31, 'Turyngia'),
  ('Lara', 'Müller', 28, 'Turyngia'),
  ('Felix', 'Weber', 29, 'Turyngia'),

  -- Bremia
  ('Emily', 'Schulz', 32, 'Bremia'),
  ('Mia', 'Fischer', 29, 'Bremia'),
  ('Jonas', 'Müller', 34, 'Bremia');

 -- Wprowadź dane do tabeli projekt.straznik dla francuskich regionów
INSERT INTO projekt.straznik (imie, nazwisko, wiek, oddzial_id) VALUES
  -- Wielka Prowansja-Alpy-Lazurowe Wybrzeże
  ('Antoine', 'Lefevre', 30, 'Wielka Prowansja-Alpy-Lazurowe Wybrzeże'),
  ('Clara', 'Dupont', 28, 'Wielka Prowansja-Alpy-Lazurowe Wybrzeże'),
  ('Lucas', 'Martin', 35, 'Wielka Prowansja-Alpy-Lazurowe Wybrzeże'),

  -- Oksytania
  ('Emma', 'Dubois', 32, 'Oksytania'),
  ('Hugo', 'Leroux', 29, 'Oksytania'),
  ('Lea', 'Bernard', 34, 'Oksytania'),

  -- Nowa Akwitania
  ('Louis', 'Lefevre', 31, 'Nowa Akwitania'),
  ('Manon', 'Dupont', 33, 'Nowa Akwitania'),
  ('Mathis', 'Martin', 27, 'Nowa Akwitania'),

  -- Normandia
  ('Camille', 'Dubois', 29, 'Normandia'),
  ('Paul', 'Leroux', 32, 'Normandia'),
  ('Léa', 'Bernard', 30, 'Normandia'),

  -- Hauts-de-France
  ('Jules', 'Lefevre', 33, 'Hauts-de-France'),
  ('Zoe', 'Dupont', 28, 'Hauts-de-France'),
  ('Enzo', 'Martin', 31, 'Hauts-de-France'),

  -- Île-de-France
  ('Manon', 'Dubois', 32, 'Île-de-France'),
  ('Louis', 'Leroux', 29, 'Île-de-France'),
  ('Inès', 'Bernard', 34, 'Île-de-France'),

  -- Grand Est
  ('Lucas', 'Lefevre', 33, 'Grand Est'),
  ('Emma', 'Dupont', 30, 'Grand Est'),
  ('Hugo', 'Martin', 29, 'Grand Est'),

  -- Korsyka
  ('Lea', 'Dubois', 32, 'Korsyka'),
  ('Mathis', 'Leroux', 28, 'Korsyka'),
  ('Manon', 'Bernard', 31, 'Korsyka'),

  -- Bretania
  ('Hugo', 'Lefevre', 29, 'Bretania'),
  ('Léa', 'Dupont', 32, 'Bretania'),
  ('Camille', 'Martin', 30, 'Bretania'),

  -- Paj-de-la-Loire
  ('Paul', 'Dubois', 31, 'Paj-de-la-Loire'),
  ('Léa', 'Leroux', 28, 'Paj-de-la-Loire'),
  ('Jules', 'Bernard', 33, 'Paj-de-la-Loire'),

  -- Kraj Loary
  ('Zoe', 'Lefevre', 32, 'Kraj Loary'),
  ('Enzo', 'Dupont', 29, 'Kraj Loary'),
  ('Inès', 'Martin', 34, 'Kraj Loary'),

  -- Burgundia-Franche-Comté
  ('Manon', 'Dubois', 33, 'Burgundia-Franche-Comté'),
  ('Louis', 'Leroux', 30, 'Burgundia-Franche-Comté'),
  ('Emma', 'Bernard', 29, 'Burgundia-Franche-Comté'),

  -- Kraj Basków
  ('Hugo', 'Lefevre', 32, 'Kraj Basków'),
  ('Camille', 'Dupont', 28, 'Kraj Basków'),
  ('Léa', 'Martin', 31, 'Kraj Basków'),

  -- Kraj Nacjonalistów
  ('Paul', 'Dubois', 29, 'Kraj Nacjonalistów'),
  ('Zoe', 'Leroux', 32, 'Kraj Nacjonalistów'),
  ('Enzo', 'Bernard', 30, 'Kraj Nacjonalistów'),

  -- Centrum-Val de Loire
  ('Manon', 'Lefevre', 33, 'Centrum-Val de Loire'),
  ('Louis', 'Dupont', 30, 'Centrum-Val de Loire'),
  ('Emma', 'Martin', 29, 'Centrum-Val de Loire'),

  -- Gwadelupa
  ('Hugo', 'Dubois', 32, 'Gwadelupa'),
  ('Camille', 'Leroux', 28, 'Gwadelupa'),
  ('Léa', 'Bernard', 31, 'Gwadelupa'),

  -- Martynika
  ('Paul', 'Lefevre', 29, 'Martynika'),
  ('Zoe', 'Dupont', 32, 'Martynika'),
  ('Enzo', 'Martin', 30, 'Martynika'),

  -- Gujana Francuska
  ('Manon', 'Dubois', 33, 'Gujana Francuska'),
  ('Louis', 'Leroux', 30, 'Gujana Francuska'),
  ('Emma', 'Bernard', 29, 'Gujana Francuska');

 


 


INSERT INTO projekt.zwierze (nazwa, gatunek, legalna)
VALUES
  ('Łosoś atlantycki', 'Ryba', TRUE),
  ('Dorsz atlantycki', 'Ryba', TRUE),
  ('Rekin biały', 'Ryba', FALSE),
  ('Żółw morski', 'Gad', TRUE),
  ('Delfin butlonosy', 'Ssak', TRUE),
  ('Orka oceaniczna', 'Ssak', FALSE),
  ('Kosatka orka', 'Ssak', FALSE),
  ('Foka pospolita', 'Ssak', TRUE),
  ('Krokodyl morski', 'Gad', FALSE),
  ('Osyka jadowita', 'Ryba', FALSE),
  ('Morski konik polny', 'Gad', TRUE),
  ('Murena europejska', 'Ryba', TRUE),
  ('Żarłacz biały', 'Ryba', FALSE),
  ('Meduza błękitna', 'Gad', FALSE),
  ('Morski żółw skórzasty', 'Gad', TRUE),
  ('Pingwin cesarski', 'Ptak', TRUE),
  ('Skalar', 'Ryba', TRUE),
  ('Sum afrykański', 'Ryba', TRUE),
  ('Żabka drzewna', 'Płaz', TRUE),
  ('Krab błękitny', 'Stawonóg', TRUE),
  ('Golfina', 'Ssak', TRUE),
  ('Żółw błotny', 'Gad', TRUE),
  ('Żółw ozdobny', 'Gad', TRUE),
  ('Osadnik błotny', 'Ptak', TRUE),
  ('Żyrafa morska', 'Ryba', FALSE),
  ('Żarłacz wielorybi', 'Ryba', TRUE),
  ('Długoszpar', 'Ryba', TRUE),
  ('Ryba skrzydłowa', 'Ryba', TRUE),
  ('Rekin wielorybi', 'Ryba', FALSE);
-- Dodaj kolejne zwierzęta według potrzeb.

 
 INSERT INTO projekt.zwierze (nazwa, gatunek, legalna)
VALUES
  ('Żarłacz tygrysi', 'Ryba', FALSE),
  ('Rybik żółty', 'Ryba', TRUE),
  ('Gwóźdź wodny', 'Gad', TRUE),
  ('Manta birostris', 'Ryba', TRUE),
  ('Gatunek X', 'Nieznany', FALSE),
  ('Żaba drzewna', 'Płaz', TRUE),
  ('Królik morski', 'Ssak', FALSE),
  ('Rekin skąposzczetny', 'Ryba', FALSE),
  ('Świnka morska', 'Ssak', TRUE),
  ('Długi płaszcz', 'Stawonóg', TRUE),
  ('Bocian czarny', 'Ptak', TRUE),
  ('Wielka karpia', 'Ryba', TRUE),
  ('Żaglowiec płetwowy', 'Ryba', TRUE),
  ('Żółw morski zielony', 'Gad', TRUE),
  ('Nurkujący pingwin', 'Ptak', TRUE),
  ('Wielki rurkowiec', 'Stawonóg', FALSE),
  ('Osaczka', 'Ryba', TRUE),
  ('Żuraw', 'Ptak', TRUE),
  ('Ośmiornica krótsza', 'Stawonóg', TRUE),
  ('Piękna syrena', 'Nieznany', TRUE),
  ('Lamparcińc płowy', 'Ryba', TRUE),
  ('Rybka akwariowa', 'Ryba', TRUE),
  ('Żuraw czarny', 'Ptak', TRUE),
  ('Myszoródka', 'Stawonóg', TRUE),
  ('Żółw błotny śmierdzący', 'Gad', FALSE),
  ('Pstry krocznik', 'Ptak', TRUE),
  ('Lusterko rybne', 'Ryba', TRUE),
  ('Rybik ćwiklawy', 'Ryba', TRUE),
  ('Rekin piłonosy', 'Ryba', FALSE);
-- Dodaj kolejne zwierzęta według potrzeb.

 INSERT INTO projekt.zwierze (nazwa, gatunek, legalna)
VALUES
  ('Pstrąg tęczowy', 'Ryba', TRUE),
  ('Rurkonóg błękitny', 'Stawonóg', TRUE),
  ('Długonoga mewa', 'Ptak', TRUE),
  ('Rogatka amazońska', 'Ryba', FALSE),
  ('Manta kolorowa', 'Ryba', TRUE),
  ('Kameleon wodny', 'Gad', FALSE),
  ('Żółw błotny szarej skóry', 'Gad', TRUE),
  ('Łasiczka morska', 'Ssak', TRUE),
  ('Skurczak białonogi', 'Stawonóg', TRUE),
  ('Kruk morski', 'Ptak', TRUE),
  ('Gwóźdź wodny zielony', 'Gad', TRUE),
  ('Wężowiec olbrzymi', 'Ryba', FALSE),
  ('Dmuchawiec morski', 'Ptak', TRUE),
  ('Strzałka morska', 'Stawonóg', TRUE),
  ('Osaczka zielona', 'Ryba', TRUE),
  ('Karpia zjadający lody', 'Ryba', TRUE),
  ('Jaskółka wodna', 'Ptak', TRUE),
  ('Zebra wodna', 'Ssak', FALSE),
  ('Pingwin kokardowy', 'Ptak', TRUE),
  ('Żabka krasnobrzucha', 'Płaz', TRUE),
  ('Rekin lśniący', 'Ryba', FALSE),
  ('Murena krótkobrzucha', 'Ryba', TRUE),
  ('Rybik malowany', 'Ryba', TRUE),
  ('Wielki chrząszcz wodny', 'Stawonóg', TRUE),
  ('Sęp morski', 'Ptak', TRUE),
  ('Wielki skowronek morski', 'Ptak', TRUE),
  ('Długonoga ropucha', 'Płaz', TRUE),
  ('Króliczek morski', 'Ssak', TRUE),
  ('Kurczak wodny', 'Ptak', TRUE),
  ('Nurkujący jeż', 'Stawonóg', TRUE);
-- Dodaj kolejne zwierzęta według potrzeb.

 INSERT INTO projekt.zwierze (nazwa, gatunek, legalna)
VALUES
  ('Żarłacz młot', 'Ryba', FALSE),
  ('Rybitwa morska', 'Ptak', TRUE),
  ('Kołomroczek', 'Stawonóg', TRUE),
  ('Ostrogon', 'Ryba', TRUE),
  ('Delfin długonosy', 'Ssak', TRUE),
  ('Krabały', 'Stawonóg', TRUE),
  ('Karas wodny', 'Ryba', TRUE),
  ('Skowron morski', 'Ptak', TRUE),
  ('Żaba czerwonobrzucha', 'Płaz', TRUE),
  ('Makrela błękitna', 'Ryba', TRUE),
  ('Wrona morska', 'Ptak', TRUE),
  ('Chruścik morski', 'Stawonóg', TRUE),
  ('Łososiowate', 'Ryba', TRUE),
  ('Mewa rzeczna', 'Ptak', TRUE),
  ('Żabka zielonobrzucha', 'Płaz', TRUE),
  ('Rak błotny', 'Stawonóg', TRUE),
  ('Rozgwiazda', 'Stawonóg', TRUE),
  ('Bielik morski', 'Ptak', TRUE),
  ('Żyrafa wodna', 'Ssak', FALSE),
  ('Rekin młot', 'Ryba', FALSE),
  ('Bocian morski', 'Ptak', TRUE),
  ('Złota rybka', 'Ryba', TRUE),
  ('Dzikopysk', 'Stawonóg', TRUE),
  ('Żółw wodny', 'Gad', TRUE),
  ('Ryba ananasowa', 'Ryba', TRUE),
  ('Fregata morska', 'Ptak', TRUE),
  ('Murena długobrzucha', 'Ryba', TRUE),
  ('Żabka zielononoga', 'Płaz', TRUE),
  ('Mewa szara', 'Ptak', TRUE);
-- Dodaj kolejne zwierzęta według potrzeb.

 INSERT INTO projekt.zwierze (nazwa, gatunek, legalna)
VALUES
  ('Żarłacz wielki', 'Ryba', FALSE),
  ('Nurek białobrzuchy', 'Ptak', TRUE),
  ('Szczupak wodny', 'Ryba', TRUE),
  ('Biegacz morski', 'Stawonóg', TRUE),
  ('Nurkujący delfin', 'Ssak', TRUE),
  ('Gawron morski', 'Ptak', TRUE),
  ('Żółw morski żółty', 'Gad', TRUE),
  ('Złoty orzeł morski', 'Ptak', TRUE),
  ('Płaz rudy', 'Płaz', TRUE),
  ('Miecznik błękitny', 'Ryba', TRUE),
  ('Wróbel morski', 'Ptak', TRUE),
  ('Jeleń morski', 'Ssak', FALSE),
  ('Krewetka błękitna', 'Stawonóg', TRUE),
  ('Żółw morski pomarańczowy', 'Gad', TRUE),
  ('Pingwin królewski', 'Ptak', TRUE),
  ('Ropucha zielona', 'Płaz', TRUE),
  ('Rak morski', 'Stawonóg', TRUE),
  ('Żuraw morski', 'Ptak', TRUE),
  ('Dzwoniec morski', 'Stawonóg', TRUE),
  ('Gąska morska', 'Ptak', TRUE),
  ('Żółw morski czerwony', 'Gad', TRUE),
  ('Płaszczka morska', 'Ryba', TRUE),
  ('Królik morski szary', 'Ssak', TRUE),
  ('Sikora morska', 'Ptak', TRUE),
  ('Mysz wodna', 'Stawonóg', TRUE),
  ('Rekin podwodny', 'Ryba', FALSE),
  ('Żabka modra', 'Płaz', TRUE),
  ('Zander', 'Ryba', TRUE),
  ('Delfin szary', 'Ssak', TRUE);
-- Dodaj kolejne zwierzęta według potrzeb.


INSERT INTO projekt.rybak (imie, nazwisko, stan_konta, wiek) VALUES
  ('Adam', 'Kowalski', 5000.00, 30),
  ('Anna', 'Nowak', 7500.50, 28),
  ('Piotr', 'Wiśniewski', 6200.75, 35),
  ('Katarzyna', 'Jankowska', 4800.25, 29),
  ('Michał', 'Kamiński', 5500.80, 34),
  ('Ewa', 'Lewandowska', 7000.00, 31),
  ('Krzysztof', 'Szymański', 8000.50, 33),
  ('Alicja', 'Dąbrowska', 6200.75, 27),
  ('Rafał', 'Wójcik', 5300.20, 32),
  ('Joanna', 'Zielińska', 4800.25, 29),
  ('Bartosz', 'Kowalczyk', 7200.90, 31),
  ('Monika', 'Kaczmarek', 5900.60, 30),
  ('Tomasz', 'Nowakowski', 6700.40, 28),
  ('Agnieszka', 'Piotrowska', 5500.80, 34),
  ('Grzegorz', 'Jankowski', 6200.75, 29),
  ('Karolina', 'Michalak', 4800.25, 31),
  ('Łukasz', 'Kowal', 7000.00, 27),
  ('Kinga', 'Kowalczyk', 8000.50, 33),
  ('Radosław', 'Włodarczyk', 6200.75, 29),
  ('Magdalena', 'Jankowska', 5300.20, 32),
  ('Mateusz', 'Szymański', 4800.25, 29),
  ('Kamila', 'Wiśniewska', 7200.90, 31),
  ('Marcin', 'Lewandowski', 5900.60, 30),
  ('Natalia', 'Kowalska', 6700.40, 28),
  ('Artur', 'Nowak', 5500.80, 34),
  ('Weronika', 'Kamińska', 6200.75, 29),
  ('Łukasz', 'Szymański', 4800.25, 31),
  ('Dominika', 'Dąbrowska', 7000.00, 27),
  ('Daniel', 'Zieliński', 8000.50, 33),
  ('Patrycja', 'Dąbrowska', 6200.75, 29),
  ('Tomasz', 'Wójcik', 5300.20, 32),
  ('Agata', 'Zielińska', 4800.25, 29),
  ('Przemysław', 'Kowalczyk', 7200.90, 31),
  ('Sylwia', 'Kowal', 5900.60, 30),
  ('Krystian', 'Michalak', 6700.40, 28),
  ('Oliwia', 'Jankowska', 5500.80, 34),
  ('Paweł', 'Kowalski', 6200.75, 29),
  ('Karolina', 'Nowakowska', 4800.25, 31),
  ('Bartłomiej', 'Nowak', 7000.00, 27),
  ('Aleksandra', 'Kowalczyk', 8000.50, 33),
  ('Jakub', 'Wiśniewski', 6200.75, 29),
  ('Natalia', 'Jankowska', 5300.20, 32),
  ('Łukasz', 'Szymański', 4800.25, 29),
  ('Katarzyna', 'Wiśniewska', 7200.90, 31),
  ('Mikołaj', 'Lewandowski', 5900.60, 30),
  ('Dominika', 'Kowalska', 6700.40, 28),
  ('Adrian', 'Kowalczyk', 5500.80, 34),
  ('Nadia', 'Kowal', 6200.75, 29),
  ('Mateusz', 'Michalak', 4800.25, 31);

 INSERT INTO projekt.rybak (imie, nazwisko, stan_konta, wiek)
VALUES
  ('Lukas', 'Schmidt', 5000.00, 30),
  ('Anna', 'Müller', 7500.50, 28),
  ('Felix', 'Schneider', 6200.75, 35),
  ('Sophie', 'Fischer', 4800.25, 29),
  ('Max', 'Weber', 5500.80, 34),
  ('Lena', 'Schulz', 7000.00, 31),
  ('Tim', 'Wagner', 8000.50, 33),
  ('Laura', 'Schäfer', 6200.75, 27),
  ('Jonas', 'Müller', 5300.20, 32),
  ('Elena', 'Koch', 4800.25, 29),
  ('Lukas', 'Schulz', 7200.90, 31),
  ('Sophia', 'Hofmann', 5900.60, 30),
  ('David', 'Wagner', 6700.40, 28),
  ('Emma', 'Schmidt', 5500.80, 34),
  ('Benjamin', 'Müller', 6200.75, 29),
  ('Mia', 'Fischer', 4800.25, 31),
  ('Julian', 'Weber', 7000.00, 27),
  ('Sophie', 'Schulz', 8000.50, 33),
  ('Leon', 'Müller', 6200.75, 29),
  ('Lara', 'Schneider', 5300.20, 32),
  ('Luca', 'Koch', 4800.25, 29),
  ('Hannah', 'Hofmann', 7200.90, 31),
  ('Nico', 'Müller', 5900.60, 30),
  ('Lara', 'Schmidt', 6700.40, 28),
  ('Finn', 'Weber', 5500.80, 34),
  ('Noah', 'Hofmann', 6200.75, 29),
  ('Sophie', 'Wagner', 4800.25, 31),
  ('Emily', 'Koch', 7000.00, 27),
  ('Liam', 'Schulz', 8000.50, 33);
 
 INSERT INTO projekt.rybak (imie, nazwisko, stan_konta, wiek)
VALUES
  ('Antoine', 'Lefevre', 5000.00, 30),
  ('Clara', 'Dupont', 7500.50, 28),
  ('Lucas', 'Martin', 6200.75, 35),
  ('Emma', 'Dubois', 4800.25, 29),
  ('Hugo', 'Leroux', 5500.80, 34),
  ('Lea', 'Bernard', 7000.00, 31),
  ('Louis', 'Lefevre', 8000.50, 33),
  ('Manon', 'Dupont', 6200.75, 27),
  ('Mathis', 'Martin', 5300.20, 32),
  ('Camille', 'Dubois', 4800.25, 29),
  ('Paul', 'Leroux', 7200.90, 31),
  ('Léa', 'Bernard', 5900.60, 30),
  ('Jules', 'Lefevre', 6700.40, 28),
  ('Zoe', 'Dupont', 5500.80, 34),
  ('Enzo', 'Martin', 6200.75, 29),
  ('Manon', 'Dubois', 4800.25, 31),
  ('Louis', 'Leroux', 7000.00, 27),
  ('Inès', 'Bernard', 8000.50, 33),
  ('Lucas', 'Lefevre', 6200.75, 29),
  ('Emma', 'Dupont', 5300.20, 32),
  ('Hugo', 'Martin', 4800.25, 29),
  ('Manon', 'Dubois', 7200.90, 31),
  ('Louis', 'Leroux', 5900.60, 30),
  ('Inès', 'Bernard', 6700.40, 28),
  ('Lucas', 'Lefevre', 5500.80, 34),
  ('Emma', 'Dupont', 6200.75, 29),
  ('Hugo', 'Martin', 4800.25, 31),
  ('Manon', 'Dubois', 7000.00, 27),
  ('Louis', 'Leroux', 8000.50, 33),
  ('Inès', 'Bernard', 6200.75, 29),
  ('Lucas', 'Lefevre', 5300.20, 32),
  ('Emma', 'Dupont', 4800.25, 29),
  ('Hugo', 'Martin', 7200.90, 31),
  ('Manon', 'Dubois', 5900.60, 30),
  ('Louis', 'Leroux', 6700.40, 28),
  ('Inès', 'Bernard', 5500.80, 34),
  ('Jules', 'Lefevre', 6200.75, 29),
  ('Zoe', 'Dupont', 4800.25, 31),
  ('Enzo', 'Martin', 7000.00, 27),
  ('Manon', 'Dubois', 8000.50, 33);

 
-- Województwo dolnośląskie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Jezioro Bystrzyckie', 123456, TRUE, 'Dolnośląskie'),
  ('Zbiornik Mietkowski', 789012, TRUE, 'Dolnośląskie'),
  ('Jezioro Złotnickie', 456789, TRUE, 'Dolnośląskie'),
  ('Zalew Kamieński', 654321, TRUE, 'Dolnośląskie'),
  ('Jezioro Wielisławskie', 987654, TRUE, 'Dolnośląskie');

-- Województwo kujawsko-pomorskie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Jezioro Gopło', 123456, TRUE, 'Kujawsko-Pomorskie'),
  ('Zbiornik Jeziorsko', 789012, TRUE, 'Kujawsko-Pomorskie'),
  ('Jezioro Charzykowskie', 456789, TRUE, 'Kujawsko-Pomorskie'),
  ('Zbiornik Turawa', 654321, TRUE, 'Kujawsko-Pomorskie'),
  ('Jezioro Żnin', 987654, TRUE, 'Kujawsko-Pomorskie');

-- Województwo lubelskie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Zalew Zemborzycki', 123456, TRUE, 'Lubelskie'),
  ('Jezioro Firlej', 789012, TRUE, 'Lubelskie'),
  ('Jezioro Białe', 456789, TRUE, 'Lubelskie'),
  ('Zbiornik Nielisz', 654321, TRUE, 'Lubelskie'),
  ('Jezioro Polesie Lubelskie', 987654, TRUE, 'Lubelskie');

-- Województwo lubuskie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Jezioro Dąbskie', 123456, TRUE, 'Lubuskie'),
  ('Zalew Sulejowski', 789012, TRUE, 'Lubuskie'),
  ('Jezioro Trześniowskie', 456789, TRUE, 'Lubuskie'),
  ('Zbiornik Rożnowo', 654321, TRUE, 'Lubuskie'),
  ('Zbiornik Myczkowskie', 987654, TRUE, 'Lubuskie');

-- Województwo łódzkie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Zbiornik Sulejowski', 123456, TRUE, 'Łódzkie'),
  ('Zbiornik Dzierżno', 789012, TRUE, 'Łódzkie'),
  ('Jezioro Włynkowo', 456789, TRUE, 'Łódzkie'),
  ('Jezioro Zduńskie', 654321, TRUE, 'Łódzkie'),
  ('Zbiornik Dłubnia', 987654, TRUE, 'Łódzkie');

-- Województwo małopolskie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Jezioro Czorsztyńskie', 123456, TRUE, 'Małopolskie'),
  ('Zalew Nowohucki', 789012, TRUE, 'Małopolskie'),
  ('Jezioro Rożnowskie', 456789, TRUE, 'Małopolskie'),
  ('Zbiornik Klimkówka', 654321, TRUE, 'Małopolskie'),
  ('Jezioro Dobczyckie', 987654, TRUE, 'Małopolskie');

-- Województwo mazowieckie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Jezioro Zegrzyńskie', 123456, TRUE, 'Mazowieckie'),
  ('Zalew Zegrzyński', 789012, TRUE, 'Mazowieckie'),
  ('Jezioro Serockie', 456789, TRUE, 'Mazowieckie'),
  ('Zbiornik Goczałkowicki', 654321, TRUE, 'Mazowieckie'),
  ('Jezioro Łaskie', 987654, TRUE, 'Mazowieckie');

-- Województwo opolskie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Zalew Turawski', 123456, TRUE, 'Opolskie'),
  ('Jezioro Nyskie', 789012, TRUE, 'Opolskie'),
  ('Zalew Krasiejów', 456789, TRUE, 'Opolskie'),
  ('Jezioro Otmuchowskie', 654321, TRUE, 'Opolskie'),
  ('Zbiornik Głębokie', 987654, TRUE, 'Opolskie');

-- Województwo podkarpackie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Zbiornik Klimkówa', 123456, TRUE, 'Podkarpackie'),
  ('Zalew Karczunek', 789012, TRUE, 'Podkarpackie'),
  ('Jezioro Solińskie', 456789, TRUE, 'Podkarpackie'),
  ('Zbiornik Ostrzycki', 654321, TRUE, 'Podkarpackie'),
  ('Jezioro Myczkowskie', 987654, TRUE, 'Podkarpackie');

-- Województwo podlaskie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Jezioro Wigry', 123456, TRUE, 'Podlaskie'),
  ('Jezioro Serwy', 789012, TRUE, 'Podlaskie'),
  ('Zalew Siemianówka', 456789, TRUE, 'Podlaskie'),
  ('Zbiornik Białystok', 654321, TRUE, 'Podlaskie'),
  ('Jezioro Hańcza', 987654, TRUE, 'Podlaskie');

-- Województwo pomorskie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Jezioro Żarnowieckie', 123456, TRUE, 'Pomorskie'),
  ('Jezioro Wdzydze', 789012, TRUE, 'Pomorskie'),
  ('Zbiornik Karsiński', 456789, TRUE, 'Pomorskie'),
  ('Zalew Karczemki', 654321, TRUE, 'Pomorskie'),
  ('Jezioro Raduńskie', 987654, TRUE, 'Pomorskie');

-- Województwo śląskie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Jezioro Goczałkowickie', 123456, TRUE, 'Śląskie'),
  ('Zbiornik Porąbka', 789012, TRUE, 'Śląskie'),
  ('Zbiornik Rybnicki', 456789, TRUE, 'Śląskie'),
  ('Jezioro Łąka', 654321, TRUE, 'Śląskie'),
  ('Zbiornik Nakło-Chechło', 987654, TRUE, 'Śląskie');

-- Województwo świętokrzyskie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Zbiornik Świętokrzyski', 123456, TRUE, 'Świętokrzyskie'),
  ('Zbiornik Chańcza', 789012, TRUE, 'Świętokrzyskie'),
  ('Zbiornik Połaniec', 456789, TRUE, 'Świętokrzyskie'),
  ('Jezioro Klimkówka', 654321, TRUE, 'Świętokrzyskie'),
  ('Jezioro Świetokrzyskie', 987654, TRUE, 'Świętokrzyskie');

-- Województwo warmińsko-mazurskie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Jezioro Śniardwy', 123456, TRUE, 'Warmińsko-Mazurskie'),
  ('Jezioro Mamry', 789012, TRUE, 'Warmińsko-Mazurskie'),
  ('Jezioro Niegocin', 456789, TRUE, 'Warmińsko-Mazurskie'),
  ('Jezioro Łuknajno', 654321, TRUE, 'Warmińsko-Mazurskie'),
  ('Jezioro Jagodne', 987654, TRUE, 'Warmińsko-Mazurskie');

-- Województwo wielkopolskie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Jezioro Powidzkie', 123456, TRUE, 'Wielkopolskie'),
  ('Jezioro Gopło Wielkie', 789012, TRUE, 'Wielkopolskie'),
  ('Jezioro Lusowskie', 456789, TRUE, 'Wielkopolskie'),
  ('Jezioro Kierskie', 654321, TRUE, 'Wielkopolskie'),
  ('Jezioro Łebsko', 987654, TRUE, 'Wielkopolskie');

-- Województwo zachodniopomorskie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Jezioro Drawsko', 123456, TRUE, 'Zachodniopomorskie'),
  ('Zbiornik Dobrzany', 789012, TRUE, 'Zachodniopomorskie'),
  ('Jezioro Bukowo', 456789, TRUE, 'Zachodniopomorskie'),
  ('Zalew Szczeciński', 654321, TRUE, 'Zachodniopomorskie');
 
 -- Bremia
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Hemelinger See', 240000, TRUE, 'Bremia'),
  ('Grambker See', 320000, TRUE, 'Bremia'),
  ('Salzgittersee', 4600000, TRUE, 'Bremia'),
  ('Eggesteinsee', 210000, TRUE, 'Bremia');

-- Hamburg
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Aussenalster', 16400000, TRUE, 'Hamburg'),
  ('Binnenalster', 1880000, TRUE, 'Hamburg'),
  ('Dove Elbe', 1900000, TRUE, 'Hamburg'),
  ('Boberger Niederung', 1350000, TRUE, 'Hamburg');

-- Hesja
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Edersee', 199000000, TRUE, 'Hesja'),
  ('Diemelsee', 3650000, TRUE, 'Hesja'),
  ('Niddastausee', 4600000, TRUE, 'Hesja'),
  ('Affolderner See', 240000, TRUE, 'Hesja');

-- Dolna Saksonia
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Zeteler Meer', 4800000, TRUE, 'Dolna Saksonia'),
  ('Dümmer', 16300000, TRUE, 'Dolna Saksonia'),
  ('Steinhuder Meer', 29000000, TRUE, 'Dolna Saksonia'),
  ('Hahnenknooper See', 550000, TRUE, 'Dolna Saksonia');

-- Nadrenia Północna-Westfalia
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Baldeneysee', 14000000, TRUE, 'Nadrenia Północna-Westfalia'),
  ('Phoenix-See', 370000, TRUE, 'Nadrenia Północna-Westfalia'),
  ('Aasee', 710000, TRUE, 'Nadrenia Północna-Westfalia'),
  ('Harkortsee', 12000000, TRUE, 'Nadrenia Północna-Westfalia');

-- Nadrenia-Palatynat
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Pfälzerwaldsee', 8700000, TRUE, 'Nadrenia-Palatynat'),
  ('Potzberge', 220000, TRUE, 'Nadrenia-Palatynat'),
  ('Silbersee', 530000, TRUE, 'Nadrenia-Palatynat'),
  ('Egelsee', 95000, TRUE, 'Nadrenia-Palatynat');

-- Brandenburgia
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Scharmützelsee', 6500000, TRUE, 'Brandenburgia'),
  ('Oberuckersee', 9000000, TRUE, 'Brandenburgia'),
  ('Steinhuder Mer', 29000000, TRUE, 'Brandenburgia'),
  ('Werbellinsee', 15000000, TRUE, 'Brandenburgia');

-- Meklemburgia-Pomorze Przednie
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Schweriner See', 61000000, TRUE, 'Meklemburgia-Pomorze Przednie'),
  ('Müritz', 319000000, TRUE, 'Meklemburgia-Pomorze Przednie'),
  ('Plauer See', 38000000, TRUE, 'Meklemburgia-Pomorze Przednie'),
  ('Dargun', 61000, TRUE, 'Meklemburgia-Pomorze Przednie');

-- Saara
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Losheimer See', 5600000, TRUE, 'Saara'),
  ('Bostalsee', 20500000, TRUE, 'Saara'),
  ('Gudingen', 35000, TRUE, 'Saara'),
  ('Oster', 42000, TRUE, 'Saara');

-- Saksonia
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Cospudener See', 23000000, TRUE, 'Saksonia'),
  ('Kulkwitzer See', 13000000, TRUE, 'Saksonia'),
  ('Geyser See', 65000, TRUE, 'Saksonia'),
  ('Döhlener See', 1300000, TRUE, 'Saksonia');

-- Saksonia-Anhalt
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Goseck', 160000, TRUE, 'Saksonia-Anhalt'),
  ('Talsperre Rappbode', 36000000, TRUE, 'Saksonia-Anhalt'),
  ('Geiseltalsee', 50000000, TRUE, 'Saksonia-Anhalt'),
  ('Bleiloch-Talsperre', 75000000, TRUE, 'Saksonia-Anhalt');

-- Szlezwik-Holsztyn
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Großer Plöner See', 297000000, TRUE, 'Szlezwik-Holsztyn'),
  ('Eutiner See', 5700000, TRUE, 'Szlezwik-Holsztyn'),
  ('Plöner See', 298000000, TRUE, 'Szlezwik-Holsztyn'),
  ('Kellersee', 1000000, TRUE, 'Szlezwik-Holsztyn');

-- Turyngia
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Talsperre Heyda', 29000000, TRUE, 'Turyngia'),
  ('Hohenwarte', 68000000, TRUE, 'Turyngia'),
  ('Hohenfelden', 4600000, TRUE, 'Turyngia'),
  ('Leibis-Lichte', 19000000, TRUE, 'Turyngia');
 
 
 -- Wielka Prowansja-Alpy-Lazurowe Wybrzeże
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac de Serre-Ponçon', 1200000000, TRUE, 'Wielka Prowansja-Alpy-Lazurowe Wybrzeże'),
  ('Lac du Verdon', 130000000, TRUE, 'Wielka Prowansja-Alpy-Lazurowe Wybrzeże'),
  ('Lac de Sainte-Croix', 76000000, TRUE, 'Wielka Prowansja-Alpy-Lazurowe Wybrzeże');

-- Oksytania
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac de Biscarrosse et de Parentis', 350000000, TRUE, 'Oksytania'),
  ('Lac du Salagou', 100000000, TRUE, 'Oksytania'),
  ('Étang de Thau', 75000000, TRUE, 'Oksytania');

-- Nowa Akwitania
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac d''Hourtin-Carcans', 1900000000, TRUE, 'Nowa Akwitania'),
  ('Lac de Vassivière', 44000000, TRUE, 'Nowa Akwitania'),
  ('Lac de Saint-Cassien', 14000000, TRUE, 'Nowa Akwitania');

-- Normandia
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac de la Forêt d''Orient', 235000000, TRUE, 'Normandia'),
  ('Lac de la Dathée', 12000000, TRUE, 'Normandia'),
  ('Lac de Caniel', 1700000, TRUE, 'Normandia');

-- Hauts-de-France
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac du Der-Chantecoq', 35000000, TRUE, 'Hauts-de-France'),
  ('Lac d''Amance', 220000, TRUE, 'Hauts-de-France'),
  ('Lac d''Orient', 60000, TRUE, 'Hauts-de-France');

-- Île-de-France
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac d''Enghien', 120000, TRUE, 'Île-de-France'),
  ('Étang de Saint-Quentin', 65000, TRUE, 'Île-de-France'),
  ('Lac de la Villette', 130000, TRUE, 'Île-de-France');

-- Grand Est
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac du Der-Chantecoqger', 35000000, TRUE, 'Grand Est'),
  ('Lac de Gérardmer', 11500000, TRUE, 'Grand Est'),
  ('Lac de Pierre-Percée', 29000000, TRUE, 'Grand Est');

-- Korsyka
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac de Creno', 4500000, TRUE, 'Korsyka'),
  ('Lac de Tolla', 1000000, TRUE, 'Korsyka'),
  ('Lac de Nino', 9000000, TRUE, 'Korsyka');

-- Bretania
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac de Guerlédan', 56300000, TRUE, 'Bretania'),
  ('Lac de Rillé', 750000, TRUE, 'Bretania'),
  ('Lac de Grand-Lieu', 62500000, TRUE, 'Bretania');

-- Paj-de-la-Loire
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac le de Grand-Lieu', 62500000, TRUE, 'Paj-de-la-Loire'),
  ('Lac d''Aiguebelette', 65000000, TRUE, 'Paj-de-la-Loire'),
  ('Lac de Pannecière', 56000000, TRUE, 'Paj-de-la-Loire');
--...
-- Kontynuuj dla pozostałych regionów, dodając odpowiednie zbiorniki.

 -- Kraj Loary
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac de Lieu', 62500000, TRUE, 'Kraj Loary'),
  ('Lac de Tillé', 750000, TRUE, 'Kraj Loary'),
  ('Lac de Grand', 62500000, TRUE, 'Kraj Loary');

-- Burgundia-Franche-Comté
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac des Settons', 10000000, TRUE, 'Burgundia-Franche-Comté'),
  ('Lac la de Pannecière', 56000000, TRUE, 'Burgundia-Franche-Comté'),
  ('Lac de Vouglans', 605000000, TRUE, 'Burgundia-Franche-Comté');

-- Kraj Basków
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac de Saint-Pée-sur-Nivelle', 6000000, TRUE, 'Kraj Basków'),
  ('Lac de Laroin', 3500000, TRUE, 'Kraj Basków'),
  ('Lac de Guiche', 2000000, TRUE, 'Kraj Basków');

-- Kraj Nacjonalistów
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac de Waroin', 3500000, TRUE, 'Kraj Nacjonalistów'),
  ('Lac de Tuiche', 2000000, TRUE, 'Kraj Nacjonalistów'),
  ('Lac de Harrieta', 1500000, TRUE, 'Kraj Nacjonalistów');

-- Centrum-Val de Loire
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac de Mill', 62500000, TRUE, 'Centrum-Val de Loire'),
  ('Lac de Killé', 750000, TRUE, 'Centrum-Val de Loire'),
  ('Lac de Granieu', 62500000, TRUE, 'Centrum-Val de Loire');

-- Guadelupa
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac de Carbet', 7000000, TRUE, 'Gwadelupa'),
  ('Lac Malécon', 2300000, TRUE, 'Gwadelupa'),
  ('Lac de Péligre', 15000000, TRUE, 'Gwadelupa');

-- Martynika
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac de la Montagne Pelée', 3000000, TRUE, 'Martynika'),
  ('Lac de Diamant', 3500000, TRUE, 'Martynika'),
  ('Lac de la Mauny', 4500000, TRUE, 'Martynika');

-- Gujana Francuska
INSERT INTO projekt.zbiornik (nazwa, objetosc, legalny, oddzial)
VALUES
  ('Lac de Témiscouata', 1650000000, TRUE, 'Gujana Francuska'),
  ('Lac du Lalagou', 33000000, TRUE, 'Gujana Francuska'),
  ('Lac de Tuerlédan', 56300000, TRUE, 'Gujana Francuska');
 
 
 
 INSERT INTO projekt.rynek (nazwa, oddzial_glowny)
VALUES
  ('Dino', 'Polska'),
  ('Frac', 'Polska'),
  ('Polomarket', 'Polska'),
  ('Top Market', 'Polska'),
  ('Topaz', 'Polska'),
  ('Społem', 'Polska');

-- Niemcy
INSERT INTO projekt.rynek (nazwa, oddzial_glowny)
VALUES
  ('Edeka', 'Niemcy'),
  ('Lidl', 'Niemcy'),
  ('Aldi', 'Niemcy'),
  ('Rewe', 'Niemcy'),
  ('Kaufland', 'Niemcy'),
  ('Penny', 'Niemcy');

-- Francja
INSERT INTO projekt.rynek (nazwa, oddzial_glowny)
VALUES
  ('Auchan', 'Francja'),
  ('Carrefour', 'Francja'),
  ('Intermarche', 'Francja'),
  ('Simply Market', 'Francja');
 
 
 
 
 
-- drop schema projekt cascade;
 
 
 
 
 