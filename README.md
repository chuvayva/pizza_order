# Pizza Order

The Pizza Order is a simple rails application that renders several orders to a user.

## What Is Special About Me

- Hotwire Turbo Steams is for dynamic page updating without page reloading
- [Money](https://github.com/RubyMoney/money) is for money calculations and formatting
- [Draper](https://github.com/drapergem/draper) is for presentation logic
- Development is fully containerized with Docker
- Makefile has the most common commands to run the project

## How Does This Work?

- Orders are available on the `/orders` endpoint
- Order total price calculated dynamically on every rendering
- User can click "Complete" button. Order dissappear from the page

### Price Calculation

The total price for a pizza order is to be calculated and displayed. For a pizza order several pizzas can be ordered, per pizza the desired size and also special requests (extra ingredients and omit ingredients) can be specified. In addition, there is a possibility to reduce the price of the order by using various discount codes.

- The price of a pizza depends on the size. Per size there is a "multiplier" that is multiplied by the base price of the pizza.
- Extra ingredients are also provided with this multiplier.
- Ingredients that are omitted during preparation do not change the price of the pizza.
- Promotion codes allow to get pizzas for free; e.g., two small salami pizzas for the price of one. Extra ingredients will still be charged though. Multiple promotion codes can be specified per order. A promotion code can also be applied more than once to the same order (a 2-for-1 code automatically reduces 4 pizzas to 2 for one order).
- A discount code reduces the total invoice amount by a percentage.

## How Run Locally

### Docker

The Pizza Order is a containerized application so you can run it using Docker. Install Docker using one of the ways from official site: https://docs.docker.com

### Application

The Pizza Order project includes a Makefile that simplifies executing common development tasks. To start the project, run:

```bash
make install
make start
```

Run rails console:

```bash
make console
```

Open application container:

```bash
make shell
```

## How Test Locally

Run rspec tests:

```bash
make test
```
