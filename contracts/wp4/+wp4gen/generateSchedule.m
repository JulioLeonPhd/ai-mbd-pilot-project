function schedule = generateSchedule(options)
%GENERATESCHEDULE Record the production receive schedule as a fixture.

arguments
    options struct
end

schedule = radardemo.schedule.createReceiveSchedule(struct());
schedule.documentVersion = "phase0-frozen";
schedule.id = "wp4-g2-schedule";
schedule.createdUtc = char(options.CreatedUtc);
schedule.producer = char(options.GeneratorVersion);
schedule.seed = options.Seeds.schedule;
schedule = wp4gen.addProvenance(schedule, options, options.Seeds.schedule, "schedule");
end
