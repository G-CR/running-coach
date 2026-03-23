from fastapi import FastAPI

from app.api.routes.feedback import router as feedback_router
from app.api.routes.goals import router as goals_router
from app.api.routes.home import router as home_router
from app.api.routes.plan import router as plan_router
from app.api.routes.workouts import router as workouts_router

app = FastAPI()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


app.include_router(goals_router)
app.include_router(workouts_router)
app.include_router(feedback_router)
app.include_router(home_router)
app.include_router(plan_router)
