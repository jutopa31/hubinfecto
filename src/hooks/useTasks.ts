import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import type { PendingTask } from '../types';

export function useTasks() {
  const [tasks, setTasks] = useState<PendingTask[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchTasks = async () => {
      try {
        // Check if Supabase is properly configured
        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
        const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

        if (!supabaseUrl || !supabaseKey ||
            supabaseUrl === 'https://placeholder.supabase.co' ||
            supabaseKey === 'placeholder-key') {
          console.warn('Supabase not configured, using empty task list');
          setTasks([]);
          setLoading(false);
          return;
        }

        const { data, error } = await supabase
          .from('pending_tasks')
          .select('*')
          .order('created_at', { ascending: false });

        if (error) {
          console.error('Error fetching tasks:', error);
          setTasks([]);
        } else {
          setTasks(data || []);
        }
      } catch (error) {
        console.error('Error connecting to Supabase:', error);
        setTasks([]);
      } finally {
        setLoading(false);
      }
    };

    fetchTasks();
  }, []);

  const addTask = async (newTask: Omit<PendingTask, 'id' | 'created_at'>) => {
    try {
      // Check if Supabase is properly configured
      const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
      const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

      if (!supabaseUrl || !supabaseKey ||
          supabaseUrl === 'https://placeholder.supabase.co' ||
          supabaseKey === 'placeholder-key') {
        console.warn('Supabase not configured, task not saved to database');
        // Create a temporary local task for demo purposes
        const tempTask = {
          ...newTask,
          id: Math.random().toString(36).substr(2, 9),
          created_at: new Date()
        };
        setTasks([tempTask, ...tasks]);
        return;
      }

      // Create a temporary patient_id if not provided and clean up the data
      const taskToInsert = {
        ...newTask,
        patient_id: newTask.patient_id || crypto.randomUUID(),
        notes: newTask.notes || null, // Convert empty string to null
        patient_name: newTask.patient_name || null
      };

      const { data, error } = await supabase
        .from('pending_tasks')
        .insert([taskToInsert])
        .select()
        .single();

      if (error) {
        console.error('Error adding task:', error);
        console.error('Error details:', JSON.stringify(error, null, 2));
        console.error('Task data being sent:', JSON.stringify(taskToInsert, null, 2));
        return;
      }

      // Add to local state for immediate UI update
      setTasks([data, ...tasks]);
    } catch (error) {
      console.error('Error saving task:', error);
    }
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