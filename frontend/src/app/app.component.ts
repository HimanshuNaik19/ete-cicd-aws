import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ApiService } from './services/api.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="container">
      <header>
        <h1>🚀 AWS CI/CD Pipeline Demo</h1>
        <p class="subtitle">Java Spring Boot + Angular on AWS EC2</p>
      </header>

      <div class="cards">
        <!-- Welcome Card -->
        <div class="card" *ngIf="welcomeData">
          <h2>📋 Application Info</h2>
          <div class="info">
            <p><strong>Message:</strong> {{ welcomeData.message }}</p>
            <p><strong>Version:</strong> {{ welcomeData.version }}</p>
            <p><strong>Environment:</strong> {{ welcomeData.environment }}</p>
            <p><strong>Technology:</strong> {{ welcomeData.technology }}</p>
          </div>
        </div>

        <!-- Health Card -->
        <div class="card" [class.healthy]="healthData?.status === 'healthy'">
          <h2>💚 Health Status</h2>
          <div class="info" *ngIf="healthData">
            <p><strong>Status:</strong> <span class="status">{{ healthData.status }}</span></p>
            <p><strong>Uptime:</strong> {{ healthData.uptime | number:'1.2-2' }} seconds</p>
            <p><strong>Memory (Max):</strong> {{ healthData.memory?.max }}</p>
            <p><strong>Memory (Used):</strong> {{ healthData.memory?.used }}</p>
            <p><strong>Memory (Free):</strong> {{ healthData.memory?.free }}</p>
          </div>
        </div>

        <!-- API Info Card -->
        <div class="card" *ngIf="apiInfo">
          <h2>ℹ️ System Information</h2>
          <div class="info">
            <p><strong>Application:</strong> {{ apiInfo.application }}</p>
            <p><strong>Backend:</strong> {{ apiInfo.backend }}</p>
            <p><strong>Frontend:</strong> {{ apiInfo.frontend }}</p>
            <p><strong>Platform:</strong> {{ apiInfo.platform }}</p>
            <p><strong>Services:</strong></p>
            <ul>
              <li *ngFor="let service of apiInfo.services">{{ service }}</li>
            </ul>
          </div>
        </div>
      </div>

      <footer>
        <p>Deployed via AWS CodePipeline → CodeBuild → CodeDeploy</p>
        <p class="tech-stack">Spring Boot (Undertow) | Angular 17 | Nginx | EC2 t2.micro</p>
      </footer>
    </div>
  `,
  styles: [`
    .container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 20px;
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    }

    header {
      text-align: center;
      margin-bottom: 40px;
      padding: 30px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      border-radius: 10px;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }

    h1 {
      margin: 0;
      font-size: 2.5em;
    }

    .subtitle {
      margin: 10px 0 0 0;
      font-size: 1.2em;
      opacity: 0.9;
    }

    .cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 20px;
      margin-bottom: 40px;
    }

    .card {
      background: white;
      border-radius: 8px;
      padding: 25px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      transition: transform 0.2s, box-shadow 0.2s;
    }

    .card:hover {
      transform: translateY(-5px);
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    }

    .card.healthy {
      border-left: 4px solid #10b981;
    }

    .card h2 {
      margin-top: 0;
      color: #333;
      font-size: 1.5em;
    }

    .info p {
      margin: 10px 0;
      color: #555;
    }

    .info strong {
      color: #333;
    }

    .status {
      color: #10b981;
      font-weight: bold;
      text-transform: uppercase;
    }

    ul {
      margin: 5px 0;
      padding-left: 20px;
    }

    li {
      color: #555;
      margin: 5px 0;
    }

    footer {
      text-align: center;
      padding: 20px;
      background: #f3f4f6;
      border-radius: 8px;
      color: #666;
    }

    footer p {
      margin: 5px 0;
    }

    .tech-stack {
      font-size: 0.9em;
      color: #888;
    }
  `]
})
export class AppComponent implements OnInit {
  welcomeData: any;
  healthData: any;
  apiInfo: any;

  constructor(private apiService: ApiService) { }

  ngOnInit() {
    this.loadData();
    // Refresh health data every 5 seconds
    setInterval(() => this.loadHealthData(), 5000);
  }

  loadData() {
    this.apiService.getWelcome().subscribe(data => this.welcomeData = data);
    this.loadHealthData();
    this.apiService.getInfo().subscribe(data => this.apiInfo = data);
  }

  loadHealthData() {
    this.apiService.getHealth().subscribe(data => this.healthData = data);
  }
}
