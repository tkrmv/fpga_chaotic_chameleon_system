function setLatexLabels(x_label, y_label, fig_title, legend_labels)

xlabel(x_label,'interpreter','latex','FontSize',13);
ylabel(y_label,'interpreter','latex','FontSize',13);
set(gca,'TickLabelInterpreter','latex','FontSize',11);

if nargin >= 3 && ~isempty(fig_title)
    ax = gca;
    ax.Title.String = fig_title;
    ax.Title.Interpreter = 'latex';
end

if nargin == 4
    leg1 = legend(legend_labels);
    set(leg1,'Interpreter','latex');
end

end