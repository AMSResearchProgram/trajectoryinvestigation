
[best_rmse,best_index] = min(rmse_macro_normalized(:,3));

% South
figure(1);clf; hold on
plot(field_data(:,2),field_data(:,1),'bo')
plot(speed_all{best_index}(:,3),throughput_all{best_index}(:,3),'r*')
xlim([0 inf])
ylim([0 inf])
legend('field data (radar)','simulation','location','northwest','fontsize',12)
xlabel('Speed (mph)')
ylabel('Throughput (vph)')
ytickformat('%,.0f')
set(gca,'fontsize',12)
title_text = ['I',char(8211),'75: S of New Tampa Blvd'];
title(title_text)

% Middle
figure(2);clf; hold on
plot(field_data(:,4),field_data(:,3),'bo')
plot(speed_all{best_index}(:,2),throughput_all{best_index}(:,2),'r*')
xlim([0 inf])
ylim([0 inf])
legend('field data (radar)','simulation','location','northwest','fontsize',12)
xlabel('Speed (mph)')
ylabel('Throughput (vph)')
ytickformat('%,.0f')
set(gca,'fontsize',12)
title_text = ['I',char(8211),'75: N of New Tampa Blvd'];
title(title_text)

% North
figure(3);clf; hold on
plot(field_data(:,6),field_data(:,5),'bo')
plot(speed_all{best_index}(:,1),throughput_all{best_index}(:,1),'r*')
xlim([0 inf])
ylim([0 inf])
legend('field data (radar)','simulation','location','northwest','fontsize',12)
xlabel('Speed (mph)')
ylabel('Throughput (vph)')
ytickformat('%,.0f')
set(gca,'fontsize',12)
title_text = ['I',char(8211),'75: S of I-275 Crossover'];
title(title_text)
