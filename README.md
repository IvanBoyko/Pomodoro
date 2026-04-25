# Pomodoro

## Screenshots

| Timer | Running | Daily Summary | Weekly Summary |
|-------|---------|---------------|----------------|
| ![Timer idle](docs/IMG_0881.PNG) | ![Timer running](docs/IMG_0884.PNG) | ![Daily Summary](docs/IMG_0885.PNG) | ![Weekly Summary](docs/IMG_0886.PNG) |

## Development

### Debug environment variables

Set in Xcode: **Product > Scheme > Edit Scheme… > Run > Arguments > Environment Variables**.
Only honoured in `DEBUG` builds.

| Variable | Effect |
|----------|--------|
| `POMODORO_DURATION` | Override the 25-minute timer with the given number of seconds (e.g. `15` for fast iteration). Defined in [TimerViewModel.swift](Pomodoro/Pomodoro/ViewModels/TimerViewModel.swift). |
