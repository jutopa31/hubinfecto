import { useState, useEffect } from 'react';
import { fakeTasks } from '../lib/fakeData';
import type { PendingTask } from '../types';

export function useTasks() {
  const [tasks, setTasks] = useState<PendingTask[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // For demo: Use fake data
    setTasks(fakeTasks);
    setLoading(false);
    
    // For real Supabase integration (uncomment when ready):
    // const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!);
    // const fetchTasks = async () => {
    //   const { data } = await supabase.from('pending_tasks').select('*');
    //   setTasks(data || []);
    //   setLoading(false);
    // };
    // fetchTasks();
  }, []);

  const addTask = (newTask: Omit<PendingTask, 'id' | 'created_at'>) => {
    const id = Math.random().toString(36).substr(2, 9);
    const created_at = new Date();
    setTasks([...tasks, { ...newTask, id, created_at }]);
    
    // For real Supabase integration:
    // supabase.from('pending_tasks').insert(newTask);
  };

  const toggleTaskStatus = (taskId: string) => {
    setTasks(tasks.map(task => 
      task.id === taskId 
        ? { 
            ...task, 
            status: task.status === 'completada' ? 'pendiente' : 'completada',
            completed_at: task.status === 'completada' ? undefined : new Date()
          }
        : task
    ));
  };

  return { tasks, addTask, toggleTaskStatus, loading };
}