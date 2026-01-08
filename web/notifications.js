/**
 * Smart Trashcan Notification System
 * Handles real-time notifications with popup display
 */

class NotificationManager {
  constructor() {
    this.supabaseUrl = 'https://ssztyskjcoilweqmheef.supabase.co';
    this.supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzenR5c2tqY29pbHdlcW1oZWVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgxODkxMjYsImV4cCI6MjA3Mzc2NTEyNn0.yP0Qihye9C7AiAhVN5_PBziCzfvgRlBu_dcdX9L9SSQ';
    this.supabase = null;
    this.currentUserId = null;
    this.notificationChannel = null;
    this.notifications = [];
    this.notificationQueue = [];
    this.isProcessing = false;
    
    this.init();
  }

  async init() {
    try {
      // Initialize Supabase client
      if (typeof supabase !== 'undefined') {
        this.supabase = supabase.createClient(this.supabaseUrl, this.supabaseAnonKey);
      } else {
        // Load Supabase JS if not available
        await this.loadSupabase();
        this.supabase = supabase.createClient(this.supabaseUrl, this.supabaseAnonKey);
      }
      
      // Create notification container
      this.createNotificationContainer();
      
      // Get current user
      await this.getCurrentUser();
      
      // Start listening for notifications
      if (this.currentUserId) {
        this.startListening();
        this.loadNotifications();
      }
      
      console.log('✅ Notification Manager initialized');
    } catch (error) {
      console.error('❌ Error initializing Notification Manager:', error);
    }
  }

  async loadSupabase() {
    return new Promise((resolve, reject) => {
      if (typeof supabase !== 'undefined') {
        resolve();
        return;
      }
      
      const script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js';
      script.onload = resolve;
      script.onerror = reject;
      document.head.appendChild(script);
    });
  }

  createNotificationContainer() {
    // Create container for notifications
    const container = document.createElement('div');
    container.id = 'notification-container';
    container.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      z-index: 10000;
      display: flex;
      flex-direction: column;
      gap: 10px;
      max-width: 400px;
      pointer-events: none;
    `;
    document.body.appendChild(container);
  }

  async getCurrentUser() {
    try {
      const { data: { user } } = await this.supabase.auth.getUser();
      this.currentUserId = user?.id || null;
      
      // Listen for auth changes
      this.supabase.auth.onAuthStateChange((event, session) => {
        this.currentUserId = session?.user?.id || null;
        if (this.currentUserId) {
          this.startListening();
          this.loadNotifications();
        } else {
          this.stopListening();
        }
      });
    } catch (error) {
      console.error('Error getting current user:', error);
    }
  }

  async loadNotifications() {
    if (!this.currentUserId) return;
    
    try {
      // Load notifications with task details if task_id exists
      const { data, error } = await this.supabase
        .from('notifications')
        .select(`
          *,
          tasks:task_id (
            id,
            title,
            created_at,
            completed_at,
            assigned_staff_id,
            assigned_to
          )
        `)
        .or(`user_id.eq.${this.currentUserId},user_id.is.null`)
        .order('created_at', { ascending: false })
        .limit(100);
      
      if (error) throw error;
      
      // Enrich notifications with task details
      this.notifications = await Promise.all((data || []).map(async (notification) => {
        if (notification.task_id && notification.data) {
          // Data already contains task info from trigger
          return notification;
        } else if (notification.task_id) {
          // Fetch task details if not in data
          const { data: taskData } = await this.supabase
            .from('tasks')
            .select('created_at, completed_at, assigned_staff_id, assigned_to')
            .eq('id', notification.task_id)
            .single();
          
          if (taskData) {
            notification.data = notification.data || {};
            notification.data.assigned_at = taskData.created_at;
            notification.data.assigned_time = this.formatDateTime(taskData.created_at);
            if (taskData.completed_at) {
              notification.data.completed_at = taskData.completed_at;
              notification.data.completed_time = this.formatDateTime(taskData.completed_at);
            }
          }
        }
        return notification;
      }));
      
      // Show unread notifications as popups
      const unreadNotifications = this.notifications.filter(n => !n.is_read);
      unreadNotifications.forEach(notification => {
        this.showPopup(notification);
      });
    } catch (error) {
      console.error('Error loading notifications:', error);
    }
  }

  startListening() {
    if (!this.currentUserId || this.notificationChannel) return;
    
    try {
      this.notificationChannel = this.supabase
        .channel(`notifications_${this.currentUserId}`)
        .on(
          'postgres_changes',
          {
            event: 'INSERT',
            schema: 'public',
            table: 'notifications',
            filter: `user_id=eq.${this.currentUserId}`
          },
          (payload) => {
            console.log('🔔 New notification received:', payload.new);
            this.handleNewNotification(payload.new);
          }
        )
        .on(
          'postgres_changes',
          {
            event: 'INSERT',
            schema: 'public',
            table: 'notifications',
            filter: 'user_id=is.null'
          },
          (payload) => {
            console.log('🔔 New global notification received:', payload.new);
            this.handleNewNotification(payload.new);
          }
        )
        .subscribe();
      
      console.log('✅ Started listening for notifications');
    } catch (error) {
      console.error('Error starting notification listener:', error);
    }
  }

  stopListening() {
    if (this.notificationChannel) {
      this.supabase.removeChannel(this.notificationChannel);
      this.notificationChannel = null;
      console.log('🛑 Stopped listening for notifications');
    }
  }

  async handleNewNotification(notification) {
    // Enrich notification with task details if task_id exists
    if (notification.task_id && !notification.data) {
      try {
        const { data: taskData } = await this.supabase
          .from('tasks')
          .select('created_at, completed_at, assigned_staff_id, assigned_to')
          .eq('id', notification.task_id)
          .single();
        
        if (taskData) {
          notification.data = notification.data || {};
          notification.data.assigned_at = taskData.created_at;
          notification.data.assigned_time = this.formatDateTime(taskData.created_at);
          if (taskData.completed_at) {
            notification.data.completed_at = taskData.completed_at;
            notification.data.completed_time = this.formatDateTime(taskData.completed_at);
          }
        }
      } catch (error) {
        console.error('Error fetching task details:', error);
      }
    }
    
    // Add to notifications list
    this.notifications.unshift(notification);
    
    // Show popup
    this.showPopup(notification);
    
    // Play sound
    this.playNotificationSound();
    
    // Update badge if exists
    this.updateBadge();
  }

  showPopup(notification) {
    const container = document.getElementById('notification-container');
    if (!container) return;
    
    // Create notification popup element
    const popup = document.createElement('div');
    popup.className = 'notification-popup';
    popup.dataset.notificationId = notification.id;
    
    const type = notification.type || 'system_alert';
    const priority = notification.priority || 'medium';
    
    // Get icon and color based on type
    const { icon, color } = this.getNotificationStyle(type);
    
    popup.style.cssText = `
      background: white;
      border-radius: 12px;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
      padding: 16px;
      min-width: 300px;
      max-width: 400px;
      pointer-events: auto;
      cursor: pointer;
      border-left: 4px solid ${color};
      animation: slideInRight 0.3s ease-out;
      position: relative;
      margin-bottom: 10px;
      transition: transform 0.2s, opacity 0.2s;
    `;
    
    // Build task info section if this is a task-related notification
    let taskInfoHtml = '';
    if (notification.data && (type === 'task_assigned' || type === 'task_completed' || type === 'task_reminder')) {
      const taskData = notification.data;
      taskInfoHtml = `
        <div style="
          margin-top: 8px;
          padding-top: 8px;
          border-top: 1px solid #eee;
          font-size: 12px;
          color: #666;
        ">
          ${taskData.assigned_time ? `
            <div style="display: flex; align-items: center; gap: 6px; margin-bottom: 4px;">
              <span style="color: #999;">📅 Assigned:</span>
              <span style="font-weight: 500; color: #333;">${this.escapeHtml(taskData.assigned_time)}</span>
            </div>
          ` : ''}
          ${taskData.completed_time ? `
            <div style="display: flex; align-items: center; gap: 6px; margin-bottom: 4px;">
              <span style="color: #999;">✅ Completed:</span>
              <span style="font-weight: 500; color: #4CAF50;">${this.escapeHtml(taskData.completed_time)}</span>
            </div>
          ` : ''}
          ${taskData.staff_name ? `
            <div style="display: flex; align-items: center; gap: 6px; margin-top: 4px;">
              <span style="color: #999;">👤 Staff:</span>
              <span style="font-weight: 500; color: #333;">${this.escapeHtml(taskData.staff_name)}</span>
            </div>
          ` : ''}
        </div>
      `;
    }
    
    popup.innerHTML = `
      <div style="display: flex; align-items: flex-start; gap: 12px;">
        <div style="
          width: 40px;
          height: 40px;
          border-radius: 50%;
          background: ${color}20;
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
          font-size: 20px;
        ">${icon}</div>
        <div style="flex: 1; min-width: 0;">
          <div style="
            font-weight: 600;
            font-size: 16px;
            color: #1a1a1a;
            margin-bottom: 4px;
            line-height: 1.3;
          ">${this.escapeHtml(notification.title)}</div>
          <div style="
            font-size: 14px;
            color: #666;
            line-height: 1.4;
            margin-bottom: 8px;
          ">${this.escapeHtml(notification.body)}</div>
          ${taskInfoHtml}
          <div style="
            font-size: 12px;
            color: #999;
            display: flex;
            align-items: center;
            gap: 8px;
            margin-top: 8px;
          ">
            <span>${this.formatTime(notification.created_at)}</span>
            ${priority === 'urgent' || priority === 'high' ? `<span style="color: ${color}; font-weight: 600;">${priority.toUpperCase()}</span>` : ''}
          </div>
        </div>
        <button class="notification-close" style="
          background: none;
          border: none;
          font-size: 20px;
          color: #999;
          cursor: pointer;
          padding: 0;
          width: 24px;
          height: 24px;
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
        ">×</button>
      </div>
    `;
    
    // Add hover effect
    popup.addEventListener('mouseenter', () => {
      popup.style.transform = 'translateX(-5px)';
    });
    
    popup.addEventListener('mouseleave', () => {
      popup.style.transform = 'translateX(0)';
    });
    
    // Close button
    const closeBtn = popup.querySelector('.notification-close');
    closeBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      this.closePopup(popup, notification.id);
    });
    
    // Click to mark as read
    popup.addEventListener('click', () => {
      this.markAsRead(notification.id);
      this.closePopup(popup, notification.id);
    });
    
    // Add to container
    container.appendChild(popup);
    
    // Auto-remove after 5 seconds (or longer for urgent)
    const autoCloseTime = priority === 'urgent' ? 10000 : 5000;
    setTimeout(() => {
      if (popup.parentNode) {
        this.closePopup(popup, notification.id);
      }
    }, autoCloseTime);
    
    // Add animation styles if not already added
    if (!document.getElementById('notification-styles')) {
      const style = document.createElement('style');
      style.id = 'notification-styles';
      style.textContent = `
        @keyframes slideInRight {
          from {
            transform: translateX(400px);
            opacity: 0;
          }
          to {
            transform: translateX(0);
            opacity: 1;
          }
        }
        
        @keyframes slideOutRight {
          from {
            transform: translateX(0);
            opacity: 1;
          }
          to {
            transform: translateX(400px);
            opacity: 0;
          }
        }
        
        .notification-popup {
          animation: slideInRight 0.3s ease-out;
        }
        
        .notification-popup.closing {
          animation: slideOutRight 0.3s ease-out;
        }
      `;
      document.head.appendChild(style);
    }
  }

  closePopup(popup, notificationId) {
    popup.classList.add('closing');
    setTimeout(() => {
      if (popup.parentNode) {
        popup.parentNode.removeChild(popup);
      }
    }, 300);
  }

  getNotificationStyle(type) {
    const styles = {
      'trashcan_full': { icon: '🚨', color: '#f44336' },
      'task_assigned': { icon: '📋', color: '#2196F3' },
      'task_completed': { icon: '✅', color: '#4CAF50' },
      'task_reminder': { icon: '⏰', color: '#FF9800' },
      'maintenance_required': { icon: '🔧', color: '#FF5722' },
      'system_alert': { icon: '⚠️', color: '#9C27B0' }
    };
    
    return styles[type] || styles['system_alert'];
  }

  async markAsRead(notificationId) {
    try {
      const { error } = await this.supabase.rpc('mark_notification_read', {
        p_notification_id: notificationId
      });
      
      if (error) throw error;
      
      // Update local cache
      const index = this.notifications.findIndex(n => n.id === notificationId);
      if (index !== -1) {
        this.notifications[index].is_read = true;
        this.notifications[index].read_at = new Date().toISOString();
      }
      
      this.updateBadge();
    } catch (error) {
      console.error('Error marking notification as read:', error);
    }
  }

  playNotificationSound() {
    try {
      // Create audio context for notification sound
      const audioContext = new (window.AudioContext || window.webkitAudioContext)();
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);
      
      oscillator.frequency.value = 800;
      oscillator.type = 'sine';
      
      gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.2);
      
      oscillator.start(audioContext.currentTime);
      oscillator.stop(audioContext.currentTime + 0.2);
    } catch (error) {
      // Fallback: use browser notification API sound
      if ('Notification' in window && Notification.permission === 'granted') {
        new Notification('New Notification', {
          silent: false
        });
      }
    }
  }

  updateBadge() {
    const unreadCount = this.notifications.filter(n => !n.is_read).length;
    
    // Update page title
    if (unreadCount > 0) {
      document.title = `(${unreadCount}) Smart Trashcan App`;
    } else {
      document.title = 'Smart Trashcan App';
    }
    
    // Dispatch custom event for Flutter integration
    window.dispatchEvent(new CustomEvent('notificationBadgeUpdate', {
      detail: { count: unreadCount }
    }));
  }

  formatTime(timestamp) {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now - date;
    
    const seconds = Math.floor(diff / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);
    
    if (seconds < 60) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
    
    return date.toLocaleDateString();
  }

  formatDateTime(timestamp) {
    if (!timestamp) return '';
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now - date;
    
    const seconds = Math.floor(diff / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);
    
    // Format: "Jan 15, 2024 at 2:30 PM" or relative time
    const options = { 
      month: 'short', 
      day: 'numeric', 
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    };
    
    // If less than 24 hours, show relative time with exact time
    if (hours < 24) {
      const timeStr = date.toLocaleTimeString('en-US', { 
        hour: 'numeric', 
        minute: '2-digit',
        hour12: true 
      });
      if (minutes < 60) {
        return `${minutes}m ago at ${timeStr}`;
      } else {
        return `${hours}h ago at ${timeStr}`;
      }
    }
    
    // Otherwise show full date and time
    return date.toLocaleString('en-US', options);
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // Public API methods
  async getAllNotifications() {
    return this.notifications;
  }

  getUnreadCount() {
    return this.notifications.filter(n => !n.is_read).length;
  }

  async markAllAsRead() {
    if (!this.currentUserId) return;
    
    try {
      const { error } = await this.supabase.rpc('mark_all_notifications_read', {
        p_user_id: this.currentUserId
      });
      
      if (error) throw error;
      
      // Update local cache
      this.notifications.forEach(n => {
        n.is_read = true;
        n.read_at = new Date().toISOString();
      });
      
      this.updateBadge();
    } catch (error) {
      console.error('Error marking all as read:', error);
    }
  }
}

// Initialize notification manager when DOM is ready
let notificationManager;

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    notificationManager = new NotificationManager();
  });
} else {
  notificationManager = new NotificationManager();
}

// Export for use in other scripts
window.NotificationManager = NotificationManager;
window.notificationManager = notificationManager;

