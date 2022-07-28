select * from public.category;
select * from public.film;
select * from public.film_category;

-- Task 1
select public.category.name, count(*) as films_count from public.film inner join public.film_category 
on public.film.film_id = public.film_category.film_id
inner join public.category on public.film_category.category_id = public.category.category_id
group by public.category.category_id
order by films_count;

-- Task 2
select * from public.film_actor;
select * from public.rental;
select * from public.inventory;

with result_table as 
(
        with rental_table_from_actor as 
        (
                select public.film_actor.actor_id as rental_table_from_actor_id, (public.rental.return_date::timestamp - public.rental.rental_date::timestamp) as time_of_rental from public.rental 
                inner join public.inventory on public.rental.inventory_id = public.inventory.inventory_id
                inner join public.film_actor on public.inventory.film_id = public.film_actor.film_id
        )
        select public.actor.actor_id, public.actor.first_name, public.actor.last_name,
        sum(time_of_rental) as sum_of_rental from rental_table_from_actor
        inner join public.actor on rental_table_from_actor_id = public.actor.actor_id
        group by public.actor.actor_id
        order by sum_of_rental desc
        limit 10
)
select actor_id, first_name, last_name, sum_of_rental from result_table
order by sum_of_rental;

-- Task 3
select * from public.payment;
select * from public.film_category;
select * from public.inventory;

select public.category.category_id, public.category.name, sum(public.payment.amount) as amount_sum from public.film_category 
inner join public.inventory on public.film_category.film_id = public.inventory.film_id
inner join public.store on public.inventory.store_id = public.store.store_id
inner join public.payment on public.store.manager_staff_id = public.payment.staff_id
inner join public.category on public.film_category.category_id = public.category.category_id
group by public.category.category_id
order by amount_sum
limit 1;

-- Task 4
select * from public.inventory;
select * from public.film;

select title from public.film as f1
where not exists(select * from public.film as f2 inner join public.inventory as i2
                 on f2.film_id = i2.film_id
                 where f1.film_id = f2.film_id);
                 
-- Task 5
select * from public.actor;
select * from public.film_category;
select * from public.category;
select * from public.film;
select * from public.film_actor;

WITH result_table AS 
(
        select public.actor.actor_id, public.actor.first_name, public.actor.last_name, count(*) as count_of_film,
        rank() over(order by count(*) desc) as rank_num
        from public.actor inner join public.film_actor 
        on public.actor.actor_id = public.film_actor.actor_id
        inner join public.film on public.film.film_id = public.film_actor.film_id
        inner join public.film_category on public.film_category.film_id = public.film.film_id
        inner join public.category on public.category.category_id = public.film_category.category_id
        where public.category.name = 'Children'
        group by public.actor.actor_id
        order by count_of_film desc
)
select actor_id, first_name, last_name, count_of_film from result_table
where rank_num < 4;

-- Task 6
select * from public.city;
select count(*) from public.customer;
select * from public.address;


with active_customer_for_city as 
(
        select public.customer.active, public.city.city_id, count(*) as active_count from public.city 
        inner join public.address on public.city.city_id = public.address.city_id
        inner join public.customer on public.customer.address_id = public.address.address_id
        where public.customer.active = 1
        group by public.customer.active, public.city.city_id
        order by public.customer.active
),
nonactive_customer_for_city as 
(
        select public.customer.active, public.city.city_id, count(*) as nonactive_count from public.city 
        inner join public.address on public.city.city_id = public.address.city_id
        inner join public.customer on public.customer.address_id = public.address.address_id
        where public.customer.active = 0
        group by public.customer.active, public.city.city_id
        order by public.customer.active
)
select public.city.city_id, public.city.city, COALESCE(active_count, 0) as active_count, COALESCE(nonactive_count, 0) as nonactive_count from public.city 
left outer join active_customer_for_city on public.city.city_id = active_customer_for_city.city_id
left outer join nonactive_customer_for_city on public.city.city_id = nonactive_customer_for_city.city_id
order by nonactive_count;

-- Task 7

select * from public.city;
select * from public.film;
select * from public.rental;
select * from public.inventory;
select * from public.customer;
select * from public.address;
select * from public.film_category;


with result_table_with_rank as
(
        with table_with_rental_category_and_city as 
        (
                with rental_table_of_hour as
                (
                        select rental_id, inventory_id, customer_id, staff_id,
                        extract(hour from (return_date::timestamp - rental_date::timestamp)) + 
                                extract(day from (return_date::timestamp - rental_date::timestamp)) * 24 as hour_of_rental 
                        from public.rental
                )
                select public.city.city_id, rental_table_of_hour.hour_of_rental, public.film_category.category_id from rental_table_of_hour 
                inner join public.inventory on rental_table_of_hour.inventory_id = public.inventory.inventory_id
                inner join public.film_category on public.inventory.film_id = public.film_category.film_id
                inner join public.customer on public.customer.customer_id = rental_table_of_hour.customer_id
                inner join public.address on public.address.address_id = public.customer.address_id
                inner join public.city on public.city.city_id = public.address.city_id
        )
        select city_id, category_id, sum(hour_of_rental) as sum_of_hour_of_rental, 
        rank() over(partition by city_id order by sum(hour_of_rental) desc) as rank_of_sum_rental from table_with_rental_category_and_city
        group by city_id, category_id
        having sum(hour_of_rental) is not null
)
select public.city.city, public.category.name, result_table_with_rank.sum_of_hour_of_rental from result_table_with_rank
inner join public.city on result_table_with_rank.city_id = public.city.city_id
inner join public.category on result_table_with_rank.category_id = public.category.category_id
where result_table_with_rank.rank_of_sum_rental = 1
and (lower(city) like 'a%' or lower(city) like '%-%')
order by sum_of_hour_of_rental desc;