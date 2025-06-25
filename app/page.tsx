"use client"

import { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Plus, Search, Users, ShoppingCart, TrendingUp, DollarSign } from "lucide-react"

interface Task {
  id: number
  title: string
  completed: boolean
  priority: "low" | "medium" | "high"
}

export default function Dashboard() {
  const [tasks, setTasks] = useState<Task[]>([
    { id: 1, title: "Réviser les composants React", completed: false, priority: "high" },
    { id: 2, title: "Implémenter l'authentification", completed: true, priority: "medium" },
    { id: 3, title: "Optimiser les performances", completed: false, priority: "low" },
  ])

  const [newTask, setNewTask] = useState("")
  const [searchTerm, setSearchTerm] = useState("")

  const addTask = () => {
    if (newTask.trim()) {
      setTasks([
        ...tasks,
        {
          id: Date.now(),
          title: newTask,
          completed: false,
          priority: "medium",
        },
      ])
      setNewTask("")
    }
  }

  const toggleTask = (id: number) => {
    setTasks(tasks.map((task) => (task.id === id ? { ...task, completed: !task.completed } : task)))
  }

  const filteredTasks = tasks.filter((task) => task.title.toLowerCase().includes(searchTerm.toLowerCase()))

  const stats = {
    totalTasks: tasks.length,
    completedTasks: tasks.filter((t) => t.completed).length,
    pendingTasks: tasks.filter((t) => !t.completed).length,
    highPriorityTasks: tasks.filter((t) => t.priority === "high" && !t.completed).length,
  }

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Tableau de Bord React</h1>
          <p className="text-gray-600">Gérez vos tâches et suivez vos progrès</p>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Tâches</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalTasks}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Terminées</CardTitle>
              <ShoppingCart className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">{stats.completedTasks}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">En Cours</CardTitle>
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-orange-600">{stats.pendingTasks}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Priorité Haute</CardTitle>
              <DollarSign className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-red-600">{stats.highPriorityTasks}</div>
            </CardContent>
          </Card>
        </div>

        {/* Task Management */}
        <Card>
          <CardHeader>
            <CardTitle>Gestion des Tâches</CardTitle>
            <CardDescription>Ajoutez, recherchez et gérez vos tâches quotidiennes</CardDescription>
          </CardHeader>
          <CardContent>
            {/* Add Task */}
            <div className="flex gap-2 mb-6">
              <Input
                placeholder="Nouvelle tâche..."
                value={newTask}
                onChange={(e) => setNewTask(e.target.value)}
                onKeyPress={(e) => e.key === "Enter" && addTask()}
                className="flex-1"
              />
              <Button onClick={addTask}>
                <Plus className="h-4 w-4 mr-2" />
                Ajouter
              </Button>
            </div>

            {/* Search */}
            <div className="relative mb-6">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
              <Input
                placeholder="Rechercher des tâches..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>

            {/* Task List */}
            <div className="space-y-3">
              {filteredTasks.map((task) => (
                <div
                  key={task.id}
                  className={`flex items-center justify-between p-4 border rounded-lg transition-colors ${
                    task.completed ? "bg-green-50 border-green-200" : "bg-white border-gray-200"
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <input
                      type="checkbox"
                      checked={task.completed}
                      onChange={() => toggleTask(task.id)}
                      className="h-4 w-4 text-blue-600 rounded"
                    />
                    <span className={task.completed ? "line-through text-gray-500" : "text-gray-900"}>
                      {task.title}
                    </span>
                  </div>
                  <Badge
                    variant={
                      task.priority === "high" ? "destructive" : task.priority === "medium" ? "default" : "secondary"
                    }
                  >
                    {task.priority === "high" ? "Haute" : task.priority === "medium" ? "Moyenne" : "Basse"}
                  </Badge>
                </div>
              ))}

              {filteredTasks.length === 0 && (
                <div className="text-center py-8 text-gray-500">
                  {searchTerm ? "Aucune tâche trouvée" : "Aucune tâche pour le moment"}
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
