from fastapi import FastAPI

from app.api.routes.goals import router as goals_router
from app.api.routes.workouts import router as workouts_router

app = FastAPI()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


app.include_router(goals_router)
app.include_router(workouts_router)
